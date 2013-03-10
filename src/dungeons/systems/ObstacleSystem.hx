package dungeons.systems;

import ash.ObjectMap;
import ash.core.Engine;
import ash.tools.ListIteratingSystem;

import dungeons.components.Position.PositionChangeListener;
import dungeons.nodes.ObstacleNode;
import dungeons.utils.Map;

class ObstacleSystem extends ListIteratingSystem<ObstacleNode>
{
    private var map:Map;
    private var listeners:ObjectMap<ObstacleNode, PositionChangeListener>;

    public function new(map:Map)
    {
        super(ObstacleNode, null, addNode, removeNode);
        this.map = map;
    }

    override public function addToEngine(engine:Engine):Void
    {
        listeners = new ObjectMap();
        super.addToEngine(engine);
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        super.removeFromEngine(engine);
        for (node in listeners.keys())
            node.position.changed.remove(listeners.get(node));
        listeners = null;
    }

    private inline function addObstacle(node:ObstacleNode):Void
    {
        map.get(node.position.x, node.position.y).numObstacles++;
    }

    private inline function removeObstacle(node:ObstacleNode, x:Int, y:Int):Void
    {
        map.get(x, y).numObstacles--;
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
        removeObstacle(node, node.position.x, node.position.y);

        var listener = listeners.get(node);
        listeners.remove(node);
        node.position.changed.remove(listener);
    }
}
