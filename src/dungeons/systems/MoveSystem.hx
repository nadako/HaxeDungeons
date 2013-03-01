package dungeons.systems;

import ash.core.Engine;
import ash.tools.ComponentPool;
import ash.tools.ListIteratingSystem;
import ash.ObjectHash;

import dungeons.components.Position;
import dungeons.nodes.PositionNode;
import dungeons.utils.Direction;
import dungeons.utils.Vector;

class MoveSystem extends ListIteratingSystem<PositionNode>
{
    private var obstacleSystem:ObstacleSystem;
    private var moveListeners:ObjectHash<PositionNode, MoveRequestListener>;

    public function new()
    {
        super(PositionNode, null, nodeAdded, nodeRemoved);
    }

    override public function addToEngine(engine:Engine):Void
    {
        obstacleSystem = engine.getSystem(ObstacleSystem);
        moveListeners = new ObjectHash();
        super.addToEngine(engine);
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        super.removeFromEngine(engine);
        for (node in moveListeners.keys())
            node.position.moveRequested.remove(moveListeners.get(node));
        moveListeners = null;
        obstacleSystem = null;
    }

    private function nodeAdded(node:PositionNode):Void
    {
        var listener = callback(onNodeMoveRequessted, node);
        moveListeners.set(node, listener);
        node.position.moveRequested.add(listener);
    }

    private function onNodeMoveRequessted(node:PositionNode, direction:Direction):Void
    {
        var position:Position = node.position;
        var target:Vector = position.getAdjacentTile(direction);
        if (!obstacleSystem.isBlocked(target.x, target.y))
            position.moveTo(target.x, target.y);
    }

    private function nodeRemoved(node:PositionNode):Void
    {
        var listener = moveListeners.get(node);
        moveListeners.remove(node);
        node.position.moveRequested.remove(listener);
    }
}
