package dungeons.components;

import dungeons.components.Equipment.EquipSlot;

enum EquipSlot
{
    Armor;
    Weapon;
}

class Equipment
{
    public var slot(default, null):EquipSlot;
    public var attackBonus(default, null):Int;
    public var defenseBonus(default, null):Int;

    public function new(slot:EquipSlot, attackBonus:Int = 0, defenseBonus:Int = 0):Void
    {
        this.slot = slot;
        this.attackBonus = attackBonus;
        this.defenseBonus = defenseBonus;
    }
}
