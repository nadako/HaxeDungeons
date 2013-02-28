package dungeons.systems;

import nme.ObjectHash;

import ash.core.Entity;
import ash.core.Engine;
import ash.tools.ListIteratingSystem;

import dungeons.components.Position;
import dungeons.nodes.ObstacleNode;

class ObstacleSystem extends ListIteratingSystem<ObstacleNode>
{
    private var obstacleMap:Grid<Array<ObstacleNode>>;
    private var listeners:ObjectHash<ObstacleNode, PositionChangeListener>;

    public function new(width:Int, height:Int)
    {
        obstacleMap = new Grid(width, height);
        super(ObstacleNode, null, addNode, removeNode);
    }

    override public function addToEngine(engine:Engine):Void
    {
        listeners = new ObjectHash();
        super.addToEngine(engine);
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        super.removeFromEngine(engine);
        for (node in listeners.keys())
            node.position.changed.remove(listeners.get(node));
        listeners = null;
        obstacleMap.clear();
    }

    public function isBlocked(x:Int, y:Int):Bool
    {
        var array:Array<ObstacleNode> = obstacleMap.get(x, y);
        return array != null && array.length > 0;
    }

    public function getBlocker(x:Int, y:Int):Entity
    {
        var array:Array<ObstacleNode> = obstacleMap.get(x, y);
        if (array != null && array.length > 0)
            return array[0].entity;
        else
            return null;
    }

    private function addObstacle(node:ObstacleNode):Void
    {
        var x:Int = node.position.x;
        var y:Int = node.position.y;
        var array:Array<ObstacleNode> = obstacleMap.get(x, y);
        if (array == null)
        {
            array = [];
            obstacleMap.set(x, y, array);
        }
        array.push(node);
    }

    private function removeObstacle(node:ObstacleNode, x:Int, y:Int):Void
    {
        obstacleMap.get(x, y).remove(node);
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
