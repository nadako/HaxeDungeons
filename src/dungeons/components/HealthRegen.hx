package dungeons.components;

import ash.signals.Signal0;

import dungeons.utils.Scheduler.IActor;

class HealthRegen implements IActor
{
    public var speed:Int;
    public var energy:Int;
    public var regenTick(default, null):Signal0;
    private var regenEnergyCost:Int;

    public function new(ticksPerRegen:Int = 1)
    {
        regenTick = new Signal0();
        speed = Constants.TICK_ENERGY;
        regenEnergyCost = ticksPerRegen * Constants.TICK_ENERGY;
        energy = -regenEnergyCost;
    }

    public function act():Int
    {
        regenTick.dispatch();
        return regenEnergyCost;
    }
}
