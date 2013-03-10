package dungeons.utils;

import ash.core.Entity;

class Map extends Grid<MapCell>
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
}

typedef MapCell =
{
    var entities:Array<Entity>;
    var numObstacles:Int;
    var numOccluders:Int;
    var inMemory:Bool;
}
