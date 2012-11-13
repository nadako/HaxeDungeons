package dungeons.systems;

import nme.geom.Point;
import nme.display.BitmapData;
import nme.display.Sprite;
import nme.ObjectHash;
import nme.geom.Rectangle;

import com.eclecticdesignstudio.motion.Actuate;

import net.richardlord.ash.core.Node;
import net.richardlord.ash.core.NodeList;
import net.richardlord.ash.core.Game;
import net.richardlord.ash.core.System;

import dungeons.Constants;
import dungeons.nodes.RenderNode;
import dungeons.components.Fighter;
import dungeons.components.Position;
import dungeons.components.Renderable;
import dungeons.render.HealthRenderer;
import dungeons.render.RenderLayer;
import dungeons.PositionMap.PositionArrayMap;

class RenderSystem extends System
{
    private var width:Int;
    private var height:Int;
    private var target:BitmapData;
    private var viewport:Rectangle;

    private var nodeList:NodeList<RenderNode>;
    private var positionHelpers:ObjectHash<RenderNode, PositionChangeListener>;
    private var positionStorage:Array<PositionArrayMap<RenderNode>>;
    private var emptyIterable:Iterable<RenderNode>;
    private var fovSystem:FOVSystem;
    private var healthRenderer:HealthRenderer;

    public function new(target:BitmapData, viewport:Rectangle, width:Int, height:Int)
    {
        this.width = width;
        this.height = height;
        this.target = target;
        this.viewport = viewport;
        emptyIterable = [];
        healthRenderer = new HealthRenderer(Constants.TILE_SIZE, 1);
    }

    override public function addToGame(game:Game):Void
    {
        fovSystem = game.getSystem(FOVSystem);

        positionHelpers = new ObjectHash();

        positionStorage = [];
        for (construct in Type.getEnumConstructs(RenderLayer))
            positionStorage.push(new PositionArrayMap(width, height));

        nodeList = game.getNodeList(RenderNode);
        for (node in nodeList)
            onNodeAdded(node);
        nodeList.nodeAdded.add(onNodeAdded);
        nodeList.nodeRemoved.add(onNodeRemoved);
    }

    override public function removeFromGame(game:Game):Void
    {
        for (node in positionHelpers.keys())
        {
            node.position.changed.remove(positionHelpers.get(node));
        }
        nodeList.nodeAdded.remove(onNodeAdded);
        nodeList.nodeRemoved.remove(onNodeRemoved);
        nodeList = null;
        positionHelpers = null;
        for (layer in positionStorage)
            layer.clear();
        positionStorage = null;

        fovSystem = null;
    }

    private function getArray(layer:RenderLayer, x:Int, y:Int):Array<RenderNode>
    {
        var storage:PositionArrayMap<RenderNode> = positionStorage[Type.enumIndex(layer)];
        return storage.getOrCreate(x, y);
    }

    private function onNodeAdded(node:RenderNode):Void
    {
        getArray(node.renderable.layer, node.position.x, node.position.y).push(node);

        var listener = callback(onNodePositionChange, node);
        node.position.changed.add(listener);
        positionHelpers.set(node, listener);
    }

    private function onNodePositionChange(node:RenderNode, oldX:Int, oldY:Int):Void
    {
        getArray(node.renderable.layer, oldX, oldY).remove(node);
        getArray(node.renderable.layer, node.position.x, node.position.y).push(node);
        if (fovSystem.getLight(node.position.x, node.position.y) > 0)
            animateMove(node, oldX, oldY);
    }

    private function animateMove(node:RenderNode, oldX:Int, oldY:Int):Void
    {
        Actuate.stop(node.renderable);
        node.renderable.animOffsetX -= (node.position.x - oldX) * Constants.TILE_SIZE;
        node.renderable.animOffsetY -= (node.position.y - oldY) * Constants.TILE_SIZE;
        Actuate.tween(node.renderable, 0.5, {animOffsetX: 0, animOffsetY: 0});
    }

    private function onNodeRemoved(node:RenderNode):Void
    {
        getArray(node.renderable.layer, node.position.x, node.position.y).remove(node);

        var listener = positionHelpers.get(node);
        node.position.changed.remove(listener);
    }

    private function getNodes(storage:PositionArrayMap<RenderNode>, x:Int, y:Int):Iterable<RenderNode>
    {
        var result:Array<RenderNode> = storage.get(x, y);
        if (result == null)
            return emptyIterable;
        else
            return result;
    }

    override public function update(time:Float):Void
    {
        target.lock();
        target.fillRect(new Rectangle(0, 0, target.width, target.height), 0);

        var startX:Int = Std.int(Math.max(0, viewport.left / Constants.TILE_SIZE));
        var startY:Int = Std.int(Math.max(0, viewport.top / Constants.TILE_SIZE));
        var endX:Int = Std.int(Math.min((viewport.right / Constants.TILE_SIZE) + 1, width));
        var endY:Int = Std.int(Math.min((viewport.bottom / Constants.TILE_SIZE) + 1, height));
        var viewOffsetX:Int = Std.int(viewport.left % Constants.TILE_SIZE);
        var viewOffsetY:Int = Std.int(viewport.top % Constants.TILE_SIZE);

        var drawPoint:Point = new Point();
        for (i in 0...positionStorage.length)
        {
            var layer = positionStorage[i];
            var isDungeonLayer:Bool = (i == Type.enumIndex(RenderLayer.Dungeon));
            for (x in startX...endX)
            {
                for (y in startY...endY)
                {
                    if (fovSystem.getLight(x, y) > 0 || (isDungeonLayer && fovSystem.inMemory(x, y)))
                    {
                        for (node in getNodes(layer, x, y))
                        {
                            var renderable:Renderable = node.renderable;
                            drawPoint.x = (x - startX) * Constants.TILE_SIZE - viewOffsetX + renderable.animOffsetX;
                            drawPoint.y = (y - startY) * Constants.TILE_SIZE - viewOffsetY + renderable.animOffsetY;
                            renderable.renderer.render(target, drawPoint);

                            var fighter:Fighter = node.entity.get(Fighter);
                            if (fighter != null)
                                healthRenderer.renderHealth(fighter, target, Std.int(drawPoint.x), Std.int(drawPoint.y) - healthRenderer.healthBarHeight - 1);
                        }
                    }
                }
            }
        }

        // render nice FOV overlay
        var rectBitmap = new BitmapData(Constants.TILE_SIZE, Constants.TILE_SIZE);
        for (x in startX...endX)
        {
            for (y in startY...endY)
            {
                var light:Float = fovSystem.getLight(x, y);
                if (light < 1)
                {
                    drawPoint.x = (x - startX) * Constants.TILE_SIZE - viewOffsetX;
                    drawPoint.y = (y - startY) * Constants.TILE_SIZE - viewOffsetY;

                    var color:Int = Std.int(255 * (1 - (0.3 + light * 0.7))) << 24;

                    rectBitmap.fillRect(rectBitmap.rect, color);
                    target.copyPixels(rectBitmap, rectBitmap.rect, drawPoint, null, null, true);
                }
            }
        }
        rectBitmap.dispose();

        target.unlock();
    }
}
