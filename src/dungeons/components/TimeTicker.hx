package dungeons.components;

import dungeons.utils.Scheduler.IActor;

class TimeTicker implements IActor
{
    public var speed:Int;
    public var energy:Int;
    public var ticks:Int;

    public function new()
    {
        this.speed = this.energy = Constants.TICK_ENERGY;
        ticks = 0;
    }

    public function act():Int
    {
        ticks++;
        return Constants.TICK_ENERGY;
    }
}
