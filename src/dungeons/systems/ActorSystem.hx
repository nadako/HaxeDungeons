package dungeons.systems;

import de.polygonal.ds.ArrayedDeque;
import de.polygonal.ds.Deque;

import net.richardlord.ash.tools.ComponentPool;
import net.richardlord.ash.core.Entity;
import net.richardlord.ash.core.Game;
import net.richardlord.ash.tools.ListIteratingSystem;

import dungeons.nodes.ActorNode;
import dungeons.components.Actor;
import dungeons.components.Move;

class ActorSystem extends ListIteratingSystem<ActorNode>
{
    private static inline var ACTION_COST:Int = 100;

    private var deque:Deque<ActorNode>;

    public function new()
    {
        super(ActorNode, null, nodeAdded, nodeRemoved);
        deque = new ArrayedDeque<ActorNode>();
    }

    private function nodeAdded(node:ActorNode):Void
    {
        deque.pushBack(node);
    }

    private function nodeRemoved(node:ActorNode):Void
    {
        deque.remove(node);
    }

    override public function removeFromGame(game:Game):Void
    {
        super.removeFromGame(game);
        deque.clear(true);
    }

    override public function update(time:Float):Void
    {
        if (deque.isEmpty())
            return;

        var node:ActorNode = deque.front();
        var actor:Actor = node.actor;

        if (actor.awaitingAction)
            return;

        if (actor.resultAction != null)
        {
            var action = actor.resultAction;
            actor.resultAction = null;
            actor.energy -= ACTION_COST;
            processAction(node.entity, action);
        }

        if (actor.energy <= 0)
        {
            actor.energy += actor.speed;
            deque.popFront();
            deque.pushBack(node);
        }

        if (actor.energy > 0)
            actor.awaitingAction = true;

    }

    private function processAction(entity:Entity, action:Action):Void
    {
        switch (action)
        {
            case Action.Move(direction):
                var move = ComponentPool.get(dungeons.components.Move);
                move.direction = direction;
                entity.add(move);
            default:
        }
    }
}
