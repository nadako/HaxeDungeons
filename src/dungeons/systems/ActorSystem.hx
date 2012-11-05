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
    private static inline var MAX_ACTORS_PER_UPDATE:Int = 1000;
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
        for (i in 0...MAX_ACTORS_PER_UPDATE)
        {
            if (deque.isEmpty())
                return;

            var node:ActorNode = deque.front();
            var actor:Actor = node.actor;

            // return if still waiting for action
            if (actor.awaitingAction)
                return;

            // if we was waiting and now got the action
            if (actor.resultAction != null)
                processActor(node);

            // if we still have energy, try to do more actions
            while (actor.energy > 0)
            {
                // request new action
                actor.requestAction();

                if (actor.awaitingAction)
                    // if there was no immediate reaction, then we wait for it
                    return;
                else
                    // else process the action and continue the loop
                    processActor(node);
            }

            // all actions processed now and actor have no energy
            // add some and push the actor back into queue
            actor.energy += actor.speed;
            deque.popFront();
            deque.pushBack(node);
        }
    }

    private inline function processActor(node:ActorNode):Void
    {
        var action:Action = node.actor.resultAction;
        node.actor.clearAction();
        node.actor.energy -= ACTION_COST;
        processAction(node.entity, action);
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
