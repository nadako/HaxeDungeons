package dungeons.systems;

import ash.core.Entity;
import ash.core.Engine;
import ash.tools.ListIteratingSystem;

import dungeons.nodes.ActorNode;
import dungeons.components.Fighter;
import dungeons.components.Position;
import dungeons.components.Door;
import dungeons.components.Actor;
import dungeons.components.Inventory;

/**
 * A system that processes all game actors.
 *
 * It manages actors' energy and ordering and runs actual
 * action code (by triggering relevant components and systems).
 *
 * However it doesn't decide what action should an actor do,
 * it requests an action from an actor instead. Other
 * systems such as AI or player input can process these
 * requests and set an action for the entity.
 **/
class ActorSystem extends ListIteratingSystem<ActorNode>
{
    public var actionEnergyCost:Int;
    public var maxActorsPerUpdate:Int;

    private var actors:List<ActorNode>;
    private var processingActor:Actor;
    private var processingActorRemoved:Bool;

    public function new(actionEnergyCost:Int = 100, maxActorsPerUpdate:Int = 100)
    {
        super(ActorNode, null, nodeAdded, nodeRemoved);

        this.actionEnergyCost = actionEnergyCost;
        this.maxActorsPerUpdate = maxActorsPerUpdate;

        actors = new List<ActorNode>();
        processingActor = null;
        processingActorRemoved = false;
    }

    private function nodeAdded(node:ActorNode):Void
    {
        // actor is added to the back of the queue
        actors.add(node);
    }

    private function nodeRemoved(node:ActorNode):Void
    {
        actors.remove(node);

        // if it's the actor we're currently processing - mark that it's removed,
        // so the update function can return early
        if (processingActor != null && node.actor == processingActor)
            processingActorRemoved = true;
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        super.removeFromEngine(engine);
        actors.clear();
        processingActor = null;
        processingActorRemoved = false;
    }

    override public function update(time:Float):Void
    {
        // process only a portion of actors in queue per tick
        for (i in 0...maxActorsPerUpdate)
        {
            // get first actor in queue
            var node:ActorNode = actors.first();

            // if queue is empty - nothing to do here
            if (node == null)
                return;

            // we actually need actor component, not the node itself
            var actor:Actor = node.actor;

            // return if still waiting for action
            if (actor.awaitingAction)
                return;

            // if we was waiting and now got the action
            if (actor.resultAction != null)
                processActor(node);

            // if the actor was removed as a result of processing action,
            // clear the flag, move on to the next actor
            if (processingActorRemoved)
            {
                processingActorRemoved = false;
                continue;
            }

            // if it's still there and has energy, try to do more actions
            while (actor.energy > 0)
            {
                // request new action
                actor.requestAction();

                if (actor.awaitingAction)
                {
                    // if there was no immediate reaction, then we wait for it
                    return;
                }
                else
                {
                    // else process the action
                    processActor(node);

                    // if the actor was removed as a result of processing action,
                    // break the loop early
                    if (processingActorRemoved)
                        break;
                }
            }

            // if the actor was removed as a result of processing actions,
            // clear the flag, move on to the next actor
            if (processingActorRemoved)
            {
                processingActorRemoved = false;
                continue;
            }

            // actor is still there, we processed all actions and it has no energy,
            // add some energy to it and push it back to queue so others can do stuff
            actor.energy += actor.speed;
            actors.add(actors.pop());
        }
    }

    /**
     * This function is actually a part of actor processing, it is factored
     * out of it because this code need to be run it two places of update function
     **/

    private inline function processActor(node:ActorNode):Void
    {
        // get the action
        var action:Action = node.actor.resultAction;

        // clear it from actor
        node.actor.clearAction();

        // spend the energy
        node.actor.energy -= actionEnergyCost;

        // save actor to a field so we can check if it's removed as a result of action processing
        processingActor = node.actor;

        // actually process action
        processAction(node.entity, action);

        // clear current processing actor, because we're not interested in checking if it's removed
        processingActor = null;
    }

    /**
     * This function does the actual work. It triggers relevant entity
     * components and systems based on action passed.
     **/

    private function processAction(entity:Entity, action:Action):Void
    {
        switch (action)
        {
            case Action.Move(direction):
                entity.get(Position).requestMove(direction);

            case Action.OpenDoor(door):
                door.get(Door).requestOpen(entity);

            case Action.Attack(defender):
                defender.get(Fighter).requestAttack(entity);

            case Action.Pickup(item):
                entity.get(Inventory).requestPickup(item);
                
            case Action.Wait:
        }
    }
}
