package dungeons.components;

import nme.geom.Point;

import net.richardlord.signals.Signal0;

class Position
{
    public var x(default, null):Int;
    public var y(default, null):Int;
    public var changed(default, null):Signal0;

    public function new(x:Int = 0, y:Int = 0)
    {
        this.x = x;
        this.y = y;
        changed = new Signal0();
    }

    public function moveTo(x:Int, y:Int):Void
    {
        this.x = x;
        this.y = y;
        changed.dispatch();
    }

    public function moveBy(dx:Int, dy:Int):Void
    {
        moveTo(x + dx, y + dy);
    }
}
