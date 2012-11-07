package dungeons.components;

import net.richardlord.signals.Signal1;
import net.richardlord.ash.core.Entity;

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
