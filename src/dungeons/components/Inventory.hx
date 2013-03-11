package dungeons.components;

import ash.core.Entity;
import ash.signals.Signal1;

class Inventory
{
    public var items(default, null):Array<Entity>;
    public var pickupRequested:Signal1<Entity>;
    
    public function new() 
    {
        items = [];
        pickupRequested = new Signal1();
    }
    
    public inline function requestPickup(item:Entity):Void 
    {
        pickupRequested.dispatch(item);
    }
}

typedef PickupListener = Entity->Void;
