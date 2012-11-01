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

import dungeons.nodes.RenderNode;
import dungeons.components.Renderable;
import dungeons.render.RenderLayer;

class RenderSystem extends System
{
    private var width:Int;
    private var height:Int;
    private var target:BitmapData;
    private var viewport:Rectangle;

    private var nodeList:NodeList<RenderNode>;
    private var positionHelpers:ObjectHash<RenderNode, PositionHelper>;
    private var positionStorage:Array<IntHash<Array<RenderNode>>>;
    private var emptyIterable:Iterable<RenderNode>;

    public function new(target:BitmapData, viewport:Rectangle, width:Int, height:Int)
    {
        this.width = width;
        this.height = height;
        this.target = target;
        this.viewport = viewport;
        emptyIterable = [];
    }

    override public function addToGame(game:Game):Void
    {
        positionHelpers = new ObjectHash<RenderNode, PositionHelper>();

        positionStorage = new Array<IntHash<Array<RenderNode>>>();
        for (construct in Type.getEnumConstructs(RenderLayer))
            positionStorage.push(new IntHash<Array<RenderNode>>());

        nodeList = game.getNodeList(RenderNode);
        for (node in nodeList)
            onNodeAdded(node);
        nodeList.nodeAdded.add(onNodeAdded);
        nodeList.nodeRemoved.add(onNodeRemoved);
    }

    override public function removeFromGame(game:Game):Void
    {
        for (listener in positionHelpers)
            listener.dispose();
        nodeList.nodeAdded.remove(onNodeAdded);
        nodeList.nodeRemoved.remove(onNodeRemoved);
        nodeList = null;
        positionHelpers = null;
        positionStorage = null;
    }

    private inline function getStorageKey(x:Int, y:Int):Int
    {
        return y * width + x;
    }

    private function getArray(layer:RenderLayer, x:Int, y:Int):Array<RenderNode>
    {
        var storage:IntHash<Array<RenderNode>> = positionStorage[Type.enumIndex(layer)];
        var key:Int = getStorageKey(x, y);
        var result:Array<RenderNode> = storage.get(key);
        if (result == null)
        {
            result = [];
            storage.set(key, result);
        }
        return result;
    }

    private function onNodeAdded(node:RenderNode):Void
    {
        positionHelpers.set(node, new PositionHelper(node, getArray));
    }

    private function onNodeRemoved(node:RenderNode):Void
    {
        var helper:PositionHelper = positionHelpers.get(node);
        positionHelpers.remove(node);
        helper.dispose();
    }

    private function getNodes(storage:IntHash<Array<RenderNode>>, x:Int, y:Int):Iterable<RenderNode>
    {
        var result:Array<RenderNode> = storage.get(getStorageKey(x, y));
        if (result == null)
            return emptyIterable;
        else
            return result;
    }

    override public function update(time:Float):Void
    {
        target.fillRect(new Rectangle(0, 0, target.width, target.height), 0);

        var startX:Int = Std.int(Math.max(0, viewport.left / Constants.TILE_SIZE));
        var startY:Int = Std.int(Math.max(0, viewport.top / Constants.TILE_SIZE));
        var endX:Int = Std.int(Math.min((viewport.right / Constants.TILE_SIZE) + 1, width));
        var endY:Int = Std.int(Math.min((viewport.bottom / Constants.TILE_SIZE) + 1, height));
        var viewOffsetX:Int = Std.int(viewport.left % Constants.TILE_SIZE);
        var viewOffsetY:Int = Std.int(viewport.top % Constants.TILE_SIZE);

        var drawPoint:Point = new Point();
        for (layer in positionStorage)
        {
            for (x in startX...endX)
            {
                for (y in startY...endY)
                {
                    for (node in getNodes(layer, x, y))
                    {
                        var renderable:Renderable = node.renderable;
                        drawPoint.x = (x - startX) * Constants.TILE_SIZE - viewOffsetX + renderable.animOffsetX;
                        drawPoint.y = (y - startY) * Constants.TILE_SIZE - viewOffsetY + renderable.animOffsetY;
                        renderable.renderer.render(target, drawPoint);
                    }
                }
            }
        }
    }
}

private class PositionHelper
{
    private var node:RenderNode;
    private var prevPosition:{var x:Int; var y:Int;};
    private var getArray:RenderLayer->Int->Int->Array<RenderNode>;

    public function new(node:RenderNode, getArray:RenderLayer->Int->Int->Array<RenderNode>):Void
    {
        this.node = node;
        this.getArray = getArray;
        prevPosition = {x: node.position.x, y: node.position.y};
        node.position.changed.add(onPositionChange);
        getArray(node.renderable.layer, prevPosition.x, prevPosition.y).push(node);
    }

    private function onPositionChange():Void
    {
        getArray(node.renderable.layer, prevPosition.x, prevPosition.y).remove(node);
        getArray(node.renderable.layer, node.position.x, node.position.y).push(node);

        animateMove();

        prevPosition.x = node.position.x;
        prevPosition.y = node.position.y;
    }

    private function animateMove():Void
    {
        Actuate.stop(node.renderable);
        node.renderable.animOffsetX -= (node.position.x - prevPosition.x) * Constants.TILE_SIZE;
        node.renderable.animOffsetY -= (node.position.y - prevPosition.y) * Constants.TILE_SIZE;
        Actuate.tween(node.renderable, 0.5, {animOffsetX: 0, animOffsetY: 0});
    }

    public function dispose():Void
    {
        getArray(node.renderable.layer, prevPosition.x, prevPosition.y).remove(node);
        node.position.changed.remove(onPositionChange);
        node = null;
        prevPosition = null;
    }
}
