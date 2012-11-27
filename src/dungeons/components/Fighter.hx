package dungeons.components;

import ash.core.Entity;
import ash.signals.Signal1;

class Fighter
{
    public var maxHP:Int;
    public var currentHP:Int;
    public var power:Int;
    public var defense:Int;

    public var attackRequested(default, null):Signal1<Entity>;

    public function new(maxHP:Int, power:Int, defense:Int)
    {
        this.maxHP = currentHP = maxHP;
        this.power = power;
        this.defense = defense;
        attackRequested = new Signal1();
    }

    public function requestAttack(attacker:Entity):Void
    {
        attackRequested.dispatch(attacker);
    }
}

typedef AttackRequestListener = Entity -> Void;
