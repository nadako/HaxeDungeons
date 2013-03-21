package dungeons.systems;

import ash.ObjectMap;
import ash.core.Entity;
import ash.core.Engine;
import ash.tools.ListIteratingSystem;

import dungeons.nodes.ActorNode;
import dungeons.components.Fighter;
import dungeons.components.Position;
import dungeons.components.Door;
import dungeons.components.Actor;
import dungeons.components.Inventory;
import dungeons.utils.Scheduler;

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
    public var maxActorsPerUpdate:Int;

    private var scheduler:Scheduler;
    private var actionListeners:ObjectMap<ActorNode, Action->Void>;

    public function new(maxActorsPerUpdate:Int = 100)
    {
        super(ActorNode, null, nodeAdded, nodeRemoved);
        this.maxActorsPerUpdate = maxActorsPerUpdate;
        scheduler = new Scheduler();
        actionListeners = new ObjectMap();
    }

    private function nodeAdded(node:ActorNode):Void
    {
        var listener:Action->Void = callback(processNodeAction, node);
        node.actor.actionReceived.add(listener);
        actionListeners.set(node, listener);

        scheduler.addActor(node.actor);
    }

    private function nodeRemoved(node:ActorNode):Void
    {
        scheduler.removeActor(node.actor);

        var listener:Action->Void = actionListeners.get(node);
        actionListeners.remove(node);
        node.actor.actionReceived.remove(listener);
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        super.removeFromEngine(engine);
        for (node in actionListeners.keys())
            node.actor.actionReceived.remove(actionListeners.get(node));
        actionListeners = null;
        scheduler = null;
    }

    override public function update(time:Float):Void
    {
        // process only a portion of actors in queue per tick
        for (i in 0...maxActorsPerUpdate)
        {
            if (!scheduler.tick())
                break;
        }
    }

    /**
     * This function does the actual work. It triggers relevant entity
     * components and systems based on action passed.
     **/
    private function processNodeAction(node:ActorNode, action:Action):Void
    {
        var entity:Entity = node.entity;
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
