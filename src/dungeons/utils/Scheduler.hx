package dungeons.utils;

/*
A simple time scheduling system based on energy. Can be used for player, monsters, hp regenerators, effect counters,
basically everything.

Loosely based on python example from this article:

http://roguebasin.roguelikedevelopment.org/index.php?title=An_elegant_time-management_system_for_roguelikes
*/

/**
 * Actor that participates in time scheduling.
 **/
interface IActor
{
    /**
     * speed is how much energy actor is given for his next turn
     **/
    var speed:Int;

    /**
     * current energy. when this goes 0 or below, actor's turn is over
     **/
    var energy:Int;

    /**
     * perform an action
     *
     * @return energy spent on the action. values < 0 mean
     * that action wasn't performed yet, so one more try
     * will be scheduled on next tick
     **/
    function act():Int;
}

/**
 * Scheduler for IActors.
 *
 * Supports locking and asynchronous actions.
 **/
class Scheduler
{
    private var queue:List<IActor>;
    private var currentActor:IActor;
    private var currentActorRemoved:Bool;
    private var lockCount:Int;

    public function new()
    {
        queue = new List<IActor>();
        currentActor = null;
        currentActorRemoved = false;
        lockCount = 0;
    }

    /**
     * Lock the scheduler so no further actions will be processed until unlocked.
     *
     * Lock is recursive, meaning that this method can be called multiple
     * times and to resume processing, unlock should be called that number of times.
     **/

    public function lock():Void
    {
        lockCount++;
    }

    /**
     * Unlock the scheduler. Can only be called if was locked before.
     * See lock method documentation.
     **/

    public function unlock():Void
    {
        if (lockCount == 0)
            throw "Cannot unlock not locked scheduler";
        lockCount--;
    }

    /**
     * Add actor to the scheduler
     **/

    public function addActor(actor:IActor):Void
    {
        queue.add(actor);
    }

    /**
     * Remove actor from the scheduler. Stops action processing
     * if this is the current actor being processed.
     **/

    public function removeActor(actor:IActor):Void
    {
        queue.remove(actor);

        if (currentActor == actor)
            currentActorRemoved = true;
    }

    /**
     * Process one actor. Does nothing if locked.
     *
     * @return true if actor was processed successfully and we're ready to move on to the next one,
     * false if we're locked, there's no actors left or the current action wasn't processed
     * in this tick (async input, for example)
     **/

    public function tick():Bool
    {
        if (lockCount > 0)
            return false;

        var actor:IActor = queue.first();
        if (actor == null)
            return false;

        while (actor.energy > 0)
        {
            currentActor = actor;
            var actionCost:Int = actor.act();
            currentActor = null;

            if (currentActorRemoved)
            {
                currentActorRemoved = false;
                return true;
            }

            if (actionCost < 0)
                return false;

            actor.energy -= actionCost;

            if (lockCount > 0)
                return false;
        }

        actor.energy += actor.speed;
        queue.add(queue.pop());

        return true;
    }
}
