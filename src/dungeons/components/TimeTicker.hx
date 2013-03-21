package dungeons.components;

import dungeons.utils.Scheduler.IActor;

class TimeTicker implements IActor
{
    public static inline var TICK_ENERGY:Int = 100;

    public var speed:Int;
    public var energy:Int;
    public var ticks:Int;

    public function new()
    {
        this.speed = this.energy = TICK_ENERGY;
        ticks = 0;
    }

    public function act():Int
    {
        ticks++;
        return TICK_ENERGY;
    }
}
