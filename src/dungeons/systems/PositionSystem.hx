package dungeons.systems;

import ash.core.Engine;
import ash.tools.ComponentPool;
import ash.tools.ListIteratingSystem;

import dungeons.components.Position;
import dungeons.nodes.PositionNode;
import dungeons.utils.Direction;
import dungeons.utils.Vector;
import dungeons.utils.MapGrid;

class PositionSystem extends ListIteratingSystem<PositionNode>
{
    private var moveListeners:Map<PositionNode, MoveRequestListener>;
    private var map:MapGrid;

    public function new(map:MapGrid)
    {
        super(PositionNode, null, nodeAdded, nodeRemoved);
        this.map = map;
    }

    override public function addToEngine(engine:Engine):Void
    {
        moveListeners = new Map<PositionNode, MoveRequestListener>();
        super.addToEngine(engine);
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        super.removeFromEngine(engine);
        for (node in moveListeners.keys())
            node.position.moveRequested.remove(moveListeners.get(node));
        moveListeners = null;
    }

    private function nodeAdded(node:PositionNode):Void
    {
        map.get(node.position.x, node.position.y).entities.push(node.entity);

        var listener = onNodeMoveRequessted.bind(node);
        moveListeners.set(node, listener);
        node.position.moveRequested.add(listener);
    }

    private function onNodeMoveRequessted(node:PositionNode, direction:Direction):Void
    {
        var position:Position = node.position;
        var target:Vector = position.getAdjacentTile(direction);
        if (map.get(target.x, target.y).numObstacles == 0)
        {
            map.get(position.x, position.y).entities.remove(node.entity);
            map.get(target.x, target.y).entities.push(node.entity);
            position.moveTo(target.x, target.y);
        }
    }

    private function nodeRemoved(node:PositionNode):Void
    {
        map.get(node.position.x, node.position.y).entities.remove(node.entity);

        var listener = moveListeners.get(node);
        moveListeners.remove(node);
        node.position.moveRequested.remove(listener);
    }
}
