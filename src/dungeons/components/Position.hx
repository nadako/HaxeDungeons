package dungeons.components;

import nme.geom.Point;

import net.richardlord.signals.Signal2;

class Position
{
    public var x(default, null):Int;
    public var y(default, null):Int;
    public var changed(default, null):Signal2<Int, Int>;

    public function new(x:Int = 0, y:Int = 0)
    {
        this.x = x;
        this.y = y;
        changed = new Signal2<Int, Int>();
    }

    public function moveTo(x:Int, y:Int):Void
    {
        if (this.x == x && this.y == y)
            return;

        var oldX:Int = this.x;
        var oldY:Int = this.y;

        this.x = x;
        this.y = y;

        changed.dispatch(oldX, oldY);
    }

    public inline function moveBy(dx:Int, dy:Int):Void
    {
        moveTo(x + dx, y + dy);
    }
}
