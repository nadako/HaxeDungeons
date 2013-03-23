package dungeons.components;

import ash.core.Entity;
import ash.signals.Signal0;
import ash.signals.Signal1;

import dungeons.components.Equipment.EquipSlot;

class Inventory
{
    public var items(default, null):Array<Entity>;
    public var pickupRequested:Signal1<Entity>;
    public var updated(default, null):Signal0;

    private var equipped(default, null):Array<Entity>;

    public function new()
    {
        items = [];
        pickupRequested = new Signal1();
        updated = new Signal0();
        equipped = [];
        for (i in Type.allEnums(EquipSlot))
            equipped.push(null);
    }

    public inline function requestPickup(item:Entity):Void
    {
        pickupRequested.dispatch(item);
    }

    public function getEquippedItems():Iterable<Entity>
    {
        var result:Array<Entity> = [];
        for (entity in equipped)
        {
            if (entity != null)
                result.push(entity);
        }
        return result;
    }

    public function getEquippedInSlot(slot:EquipSlot):Entity
    {
        return equipped[Type.enumIndex(slot)];
    }

    public function equip(entity:Entity):Void
    {
        if (Lambda.indexOf(items, entity) == -1)
            throw "item not in inventory";

        var equipment:Equipment = entity.get(Equipment);
        if (equipment == null)
            throw "item can't be equipped";

        equipped[Type.enumIndex(equipment.slot)] = entity;
    }

    public function deequip(slot:EquipSlot):Void
    {
        equipped[Type.enumIndex(slot)] = null;
    }
}

typedef PickupListener = Entity -> Void;
