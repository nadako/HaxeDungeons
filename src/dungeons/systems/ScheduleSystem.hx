package dungeons.systems;

import ash.core.System;

import dungeons.utils.Scheduler;

/**
 * A system that runs game scheduler. It doesn't work with any entities,
 * instead it just runs a number of scheduler ticks each update.
 **/
class ScheduleSystem extends System
{
    public var scheduler(default, null):Scheduler;
    public var ticksPerUpdate:Int;

    public function new(scheduler:Scheduler, ticksPerUpdate:Int = 1000)
    {
        super();
        this.scheduler = scheduler;
        this.ticksPerUpdate = ticksPerUpdate;
    }

    override public function update(time:Float):Void
    {
        for (i in 0...ticksPerUpdate)
        {
            if (!scheduler.tick()) // if false, we're still waiting for an action
                break;
        }
    }
}
