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
 * A system that processes creatures like
 * player or monsters.
 *
 * It adds their actors to the game scheduler
 * and handles their actions by parsing
 * action value received by AI or player
 * input and triggering relevant components
 * to be processed by their own systems.
 **/
class ActorSystem extends ListIteratingSystem<ActorNode>
{
    private var scheduler:Scheduler;
    private var actionListeners:ObjectMap<ActorNode, Action -> Void>;

    public function new(scheduler:Scheduler)
    {
        super(ActorNode, null, nodeAdded, nodeRemoved);
        this.scheduler = scheduler;
    }

    override public function addToEngine(engine:Engine):Void
    {
        actionListeners = new ObjectMap();
        super.addToEngine(engine);
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        super.removeFromEngine(engine);
        for (node in actionListeners.keys())
            node.actor.actionReceived.remove(actionListeners.get(node));
        actionListeners = null;
    }

    private function nodeAdded(node:ActorNode):Void
    {
        var listener:Action -> Void = processNodeAction.bind(node);
        node.actor.actionReceived.add(listener);
        actionListeners.set(node, listener);

        scheduler.addActor(node.actor);
    }

    private function nodeRemoved(node:ActorNode):Void
    {
        scheduler.removeActor(node.actor);

        var listener:Action -> Void = actionListeners.get(node);
        actionListeners.remove(node);
        node.actor.actionReceived.remove(listener);
    }

    private function processNodeAction(node:ActorNode, action:Action):Void
    {
        var entity:Entity = node.entity;
        switch (action)
        {
            case Action.Move(direction):
                entity.get(Position).requestMove(direction);

            case Action.OpenDoor(door):
                door.get(Door).requestOpen(entity);

            case Action.CloseDoor(door):
                door.get(Door).requestClose(entity);

            case Action.Attack(defender):
                defender.get(Fighter).requestAttack(entity);

            case Action.Pickup(item):
                entity.get(Inventory).requestPickup(item);

            case Action.Wait:
        }
    }
}
