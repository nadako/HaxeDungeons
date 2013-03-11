package dungeons.components;

import ash.core.Entity;
import ash.signals.Signal1;

class Door
{
    public var open(default, null):Bool;
    public var openRequested(default, null):Signal1<Entity>;

    public function new(open:Bool = false)
    {
        this.open = open;
        openRequested = new Signal1();
    }

    public function requestOpen(who:Entity):Void
    {
        openRequested.dispatch(who);
    }
}

typedef OpenRequestListener = Entity -> Void;
