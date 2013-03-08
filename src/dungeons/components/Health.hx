package dungeons.components;

import ash.signals.Signal0;

class Health
{
    public var maxHP(default, set_maxHP):Int;
    public var currentHP(default, set_currentHP):Int;
    public var updated(default, null):Signal0;

    public function new(maxHP:Int, currentHP:Int = -1)
    {
        updated = new Signal0();
        this.maxHP = maxHP;
        this.currentHP = (currentHP == -1) ? maxHP : currentHP;
    }

    private inline function set_currentHP(value:Int):Int
    {
        if (currentHP != value)
        {
            currentHP = value;
            updated.dispatch();
        }
        return currentHP;
    }

    private inline function set_maxHP(value:Int):Int
    {
        if (maxHP != value)
        {
            maxHP = value;
            updated.dispatch();
        }
        return maxHP;
    }
}
