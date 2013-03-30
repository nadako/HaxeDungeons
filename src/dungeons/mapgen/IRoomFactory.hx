package dungeons.mapgen;

import dungeons.mapgen.Dungeon.Tile;
import dungeons.utils.Direction;
import dungeons.utils.Grid;

interface IRoomFactory
{
    function generateRoomGrid():Grid<RoomCellInfo>;
}

typedef RoomCellInfo =
{
    var tile:Tile;
    var canBeConnected:Bool;
    var direction:Direction;
}
