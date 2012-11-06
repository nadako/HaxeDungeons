package dungeons.systems;

import nme.ObjectHash;

import net.richardlord.ash.core.Entity;
import net.richardlord.ash.core.Game;
import net.richardlord.ash.tools.ListIteratingSystem;

import dungeons.components.Position;
import dungeons.nodes.ObstacleNode;

class ObstacleSystem extends ListIteratingSystem<ObstacleNode>
{
    private var obstacleMap:IntHash<Array<ObstacleNode>>;
    private var listeners:ObjectHash<ObstacleNode, PositionChangeListener>;
    private var width:Int;
    private var height:Int;

    public function new(width:Int, height:Int)
    {
        this.width = width;
        this.height = height;
        super(ObstacleNode, null, addNode, removeNode);
    }

    override public function addToGame(game:Game):Void
    {
        obstacleMap = new IntHash();
        listeners = new ObjectHash();
        super.addToGame(game);
    }

    override public function removeFromGame(game:Game):Void
    {
        super.removeFromGame(game);
        for (node in listeners.keys())
            node.position.changed.remove(listeners.get(node));
        listeners = null;
        obstacleMap = null;
    }

    public function isBlocked(x:Int, y:Int):Bool
    {
        if (x < 0 || x >= width || y < 0 || x >= height)
            return true;

        var array:Array<ObstacleNode> = obstacleMap.get(getPositionKey(x, y));
        return array != null && array.length > 0;
    }

    public function getBlocker(x:Int, y:Int):Entity
    {
        if (x < 0 || x >= width || y < 0 || x >= height)
            return null;

        var array:Array<ObstacleNode> = obstacleMap.get(getPositionKey(x, y));
        if (array != null && array.length > 0)
            return array[0].entity;
        else
            return null;
    }

    private inline function getPositionKey(x:Int, y:Int):Int
    {
        return y * width + x;
    }

    private function addObstacle(node:ObstacleNode):Void
    {
        var key:Int = getPositionKey(node.position.x, node.position.y);
        var array:Array<ObstacleNode> = obstacleMap.get(key);
        if (array == null)
        {
            array = [];
            obstacleMap.set(key, array);
        }
        array.push(node);
    }

    private function removeObstacle(node:ObstacleNode, x:Int, y:Int):Void
    {
        var key:Int = getPositionKey(x, y);
        var array:Array<ObstacleNode> = obstacleMap.get(key);
        array.remove(node);
    }

    private function addNode(node:ObstacleNode):Void
    {
        addObstacle(node);
        var listener = callback(onNodePositionChanged, node);
        node.position.changed.add(listener);
        listeners.set(node, listener);
    }

    private function onNodePositionChanged(node:ObstacleNode, oldX:Int, oldY:Int):Void
    {
        removeObstacle(node, oldX, oldY);
        addObstacle(node);
    }

    private function removeNode(node:ObstacleNode):Void
    {
        var listener = listeners.get(node);
        listeners.remove(node);
        node.position.changed.remove(listener);
        removeObstacle(node, node.position.x, node.position.y);
    }
}
