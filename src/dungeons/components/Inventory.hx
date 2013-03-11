package dungeons.components;

import ash.core.Entity;
import ash.signals.Signal0;
import ash.signals.Signal1;

class Inventory
{
    public var items(default, null):Array<Entity>;
    public var pickupRequested:Signal1<Entity>;
    public var updated(default, null):Signal0;

    public function new()
    {
        items = [];
        pickupRequested = new Signal1();
        updated = new Signal0();
    }

    public inline function requestPickup(item:Entity):Void
    {
        pickupRequested.dispatch(item);
    }
}

typedef PickupListener = Entity -> Void;
