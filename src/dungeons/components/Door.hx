package dungeons.components;

import ash.core.Entity;
import ash.signals.Signal1;

class Door
{
    public var open:Bool;
    public var openRequested(default, null):Signal1<Entity>;
    public var closeRequested(default, null):Signal1<Entity>;

    public function new(open:Bool = false)
    {
        this.open = open;
        openRequested = new Signal1();
        closeRequested = new Signal1();
    }

    public function requestOpen(who:Entity):Void
    {
        openRequested.dispatch(who);
    }

    public function requestClose(who:Entity):Void
    {
        closeRequested.dispatch(who);
    }
}

typedef OpenRequestListener = Entity -> Void;
typedef CloseRequestListener = Entity -> Void;
