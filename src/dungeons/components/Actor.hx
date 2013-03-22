package dungeons.components;

import ash.core.Entity;
import ash.signals.Signal0;
import ash.signals.Signal1;

import dungeons.utils.Direction;
import dungeons.utils.Scheduler.IActor;

enum Action
{
    Wait;
    Move(direction:Direction);
    OpenDoor(door:Entity);
    CloseDoor(door:Entity);
    Attack(defender:Entity);
    Pickup(item:Entity);
}

/**
 * IActor implementation for monsters and player
 **/
class Actor implements IActor
{
    public static inline var ACTION_ENERGY_COST:Int = 100;

    // see IActor docs
    public var energy:Int;
    public var speed:Int;

    // signal to be processed by AI or input systems
    public var actionRequested(default, null):Signal0;

    // signal to be processed by actor system to perform actual stuff
    public var actionReceived(default, null):Signal1<Action>;

    // if we're still waiting for action to be decided
    public var awaitingAction(default, null):Bool;

    private var resultAction:Action;

    public function new(speed:Int)
    {
        this.speed = speed;
        this.energy = speed;

        actionRequested = new Signal0();
        actionReceived = new Signal1();

        awaitingAction = false;
        resultAction = null;
    }

    // see IActor docs
    public function act():Int
    {
        // if we're still waiting for input, return till better times
        if (awaitingAction)
            return -1;

        // if we haven't got any action from input, request one
        if (resultAction == null)
        {
            awaitingAction = true;
            actionRequested.dispatch();
        }

        // if it wasn't set immediately by signal handler,
        // it's asynchronous, return till better times
        if (resultAction == null)
            return -1;

        // if we have a result action - dispatch a signal to do actual job
        actionReceived.dispatch(resultAction);

        // clear processed action
        resultAction = null;

        // return energy to withdraw as a result of action
        return ACTION_ENERGY_COST;
    }

    /**
     * Set the action as a result of request.
     * Called by AI or input systems.
     **/
    public function setAction(action:Action):Void
    {
        if (!awaitingAction)
            throw "Tried to set action when not requested";
        awaitingAction = false;
        resultAction = action;
    }
}
