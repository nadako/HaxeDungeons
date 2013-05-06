package dungeons.utils;

import ash.core.Entity;

class MapGrid extends Grid<MapCell>
{
    public function new(width:Int, height:Int)
    {
        super(width, height);
        for (i in 0...width * height)
            content[i] = {
            entities: [],
            numObstacles: 0,
            numOccluders: 0,
            inMemory: false
            };
    }

    public inline function isBlocked(x:Int, y:Int):Bool
    {
        return get(x, y).numObstacles > 0;
    }
}

typedef MapCell =
{
    var entities:Array<Entity>;
    var numObstacles:Int;
    var numOccluders:Int;
    var inMemory:Bool;
}
