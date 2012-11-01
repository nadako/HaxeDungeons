package dungeons.systems;

import nme.ObjectHash;

import net.richardlord.ash.core.Game;
import net.richardlord.ash.tools.ListIteratingSystem;

import dungeons.components.Position;
import dungeons.nodes.ObstacleNode;

class ObstacleSystem extends ListIteratingSystem<ObstacleNode>
{
    private var obstacleMap:IntHash<Int>;
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

        return obstacleMap.get(getPositionKey(x, y)) > 0;
    }

    private inline function getPositionKey(x:Int, y:Int):Int
    {
        return y * width + x;
    }

    private function addObstacle(x:Int, y:Int):Void
    {
        var key:Int = getPositionKey(x, y);
        var value:Int = obstacleMap.get(key);
        obstacleMap.set(key, value + 1);
    }

    private function removeObstacle(x:Int, y:Int):Void
    {
        var key:Int = getPositionKey(x, y);
        var value:Int = obstacleMap.get(key);
        obstacleMap.set(key, Std.int(Math.max(0, value - 1)));
    }

    private function addNode(node:ObstacleNode):Void
    {
        addObstacle(node.position.x, node.position.y);
        var listener = callback(onNodePositionChanged, node);
        node.position.changed.add(listener);
        listeners.set(node, listener);
    }

    private function onNodePositionChanged(node:ObstacleNode, oldX:Int, oldY:Int):Void
    {
        removeObstacle(oldX, oldY);
        addObstacle(node.position.x, node.position.y);
    }

    private function removeNode(node:ObstacleNode):Void
    {
        var listener = listeners.get(node);
        listeners.remove(node);
        node.position.changed.remove(listener);
        removeObstacle(node.position.x, node.position.y);
    }
}
