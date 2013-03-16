package dungeons.components;

import dungeons.utils.Vector;

class MonsterAI
{
    public var lastKnownPlayerPosition(default, null):Vector;
    public var sightRadius:Int;

    public function new(sightRadius:Int = 10)
    {
        this.sightRadius = sightRadius;
    }

    public inline function setLastKnownPlayerPosition(x:Int, y:Int):Void
    {
        if (lastKnownPlayerPosition == null)
        {
            lastKnownPlayerPosition = {x: x, y: y};
        }
        else
        {
            lastKnownPlayerPosition.x = x;
            lastKnownPlayerPosition.y = y;
        }
    }

    public inline function clearLastKnownPlayerPosition():Void
    {
        lastKnownPlayerPosition = null;
    }
}
