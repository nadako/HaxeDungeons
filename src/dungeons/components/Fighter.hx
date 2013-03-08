package dungeons.components;

import ash.core.Entity;
import ash.signals.Signal1;

class Fighter
{
    public var power:Int;
    public var defense:Int;

    public var attackRequested(default, null):Signal1<Entity>;

    public function new(power:Int, defense:Int)
    {
        this.power = power;
        this.defense = defense;
        attackRequested = new Signal1();
    }

    public inline function requestAttack(attacker:Entity):Void
    {
        attackRequested.dispatch(attacker);
    }
}

typedef AttackRequestListener = Entity -> Void;
