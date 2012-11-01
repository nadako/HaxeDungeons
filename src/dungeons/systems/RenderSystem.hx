package dungeons.systems;

import de.polygonal.ds.Array2;
import dungeons.nodes.RenderNode;
import nme.geom.Point;
import nme.display.BitmapData;
import nme.display.Sprite;
import nme.ObjectHash;
import nme.geom.Rectangle;

import net.richardlord.ash.core.Node;
import net.richardlord.ash.core.NodeList;
import net.richardlord.ash.core.Game;
import net.richardlord.ash.core.System;


class RenderSystem extends System
{
    private var width:Int;
    private var height:Int;
    private var target:BitmapData;
    private var viewport:Rectangle;

    private var nodeList:NodeList<RenderNode>;
    private var positionHelpers:ObjectHash<RenderNode, PositionHelper>;
    private var positionStorage:Array2<Array<RenderNode>>;
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
        positionStorage = new Array2<Array<RenderNode>>(width, height);
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

    private function onNodeAdded(node:RenderNode):Void
    {
        positionHelpers.set(node, new PositionHelper(node, positionStorage));
    }

    private function onNodeRemoved(node:RenderNode):Void
    {
        var helper:PositionHelper = positionHelpers.get(node);
        positionHelpers.remove(node);
        helper.dispose();
    }

    private function getNodes(x:Int, y:Int):Iterable<RenderNode>
    {
        var result:Array<RenderNode> = positionStorage.get(x, y);
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
        var offsetX:Int = Std.int(viewport.left % Constants.TILE_SIZE);
        var offsetY:Int = Std.int(viewport.top % Constants.TILE_SIZE);

        for (x in startX...endX)
        {
            for (y in startY...endY)
            {
                var drawPosition:Point = new Point((x - startX) * Constants.TILE_SIZE - offsetX, (y - startY) * Constants.TILE_SIZE - offsetY);
                for (node in getNodes(x, y))
                {
                    node.renderable.renderer.render(target, drawPosition);
                }
            }
        }
    }
}

private class PositionHelper
{
    private var node:RenderNode;
    private var storage:Array2<Array<RenderNode>>;
    private var prevPosition:{var x:Int; var y:Int;};

    public function new(node:RenderNode, storage:Array2<Array<RenderNode>>):Void
    {
        this.node = node;
        this.storage = storage;
        prevPosition = {x: node.position.x, y: node.position.y};
        node.position.changed.add(onPositionChange);
        getArray(prevPosition.x, prevPosition.y).push(node);
    }

    private inline function getArray(x:Int, y:Int):Array<RenderNode>
    {
        var result:Array<RenderNode> = storage.get(x, y);
        if (result == null)
        {
            result = [];
            storage.set(x, y, result);
        }
        return result;
    }

    private function onPositionChange():Void
    {
        getArray(prevPosition.x, prevPosition.y).remove(node);
        getArray(node.position.x, node.position.y).push(node);
        prevPosition.x = node.position.x;
        prevPosition.y = node.position.y;
    }

    public function dispose():Void
    {
        getArray(prevPosition.x, prevPosition.y).remove(node);
        node.position.changed.remove(onPositionChange);
        node = null;
        prevPosition = null;
    }
}
