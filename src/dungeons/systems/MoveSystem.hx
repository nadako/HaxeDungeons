package dungeons.systems;

import net.richardlord.ash.core.Game;
import net.richardlord.ash.tools.ComponentPool;
import net.richardlord.ash.tools.ListIteratingSystem;

import nme.ObjectHash;

import dungeons.components.Position;
import dungeons.nodes.PositionNode;
import dungeons.Dungeon;

class MoveSystem extends ListIteratingSystem<PositionNode>
{
    private var obstacleSystem:ObstacleSystem;
    private var moveListeners:ObjectHash<PositionNode, MoveRequestListener>;

    public function new()
    {
        super(PositionNode, null, nodeAdded, nodeRemoved);
    }

    override public function addToGame(game:Game):Void
    {
        obstacleSystem = game.getSystem(ObstacleSystem);
        moveListeners = new ObjectHash();
        super.addToGame(game);
    }

    override public function removeFromGame(game:Game):Void
    {
        super.removeFromGame(game);
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
        var target = position.getAdjacentTile(direction);
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
