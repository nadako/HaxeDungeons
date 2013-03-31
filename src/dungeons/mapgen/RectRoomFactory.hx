package dungeons.mapgen;

import com.haxepunk.HXP;

import dungeons.mapgen.Dungeon.Tile;
import dungeons.mapgen.IRoomFactory.RoomCellInfo;
import dungeons.utils.Direction;
import dungeons.utils.Grid;
import dungeons.utils.Vector;

class RectRoomFactory implements IRoomFactory
{
    public var minRoomSize:Vector;
    public var maxRoomSize:Vector;

    public function new(minRoomSize:Vector, maxRoomSize:Vector)
    {
        this.minRoomSize = minRoomSize;
        this.maxRoomSize = maxRoomSize;
    }

    public function generateRoomGrid():Grid<RoomCellInfo>
    {
        var w:Int = minRoomSize.x + HXP.rand(maxRoomSize.x - minRoomSize.x + 1);
        var h:Int = minRoomSize.y + HXP.rand(maxRoomSize.y - minRoomSize.y + 1);

        var roomGrid:Grid<RoomCellInfo> = new Grid(w, h);
        for (y in 0...h)
        {
            for (x in 0...w)
            {
                var tile:Tile;
                var canBeConnected:Bool = false;
                var direction:Direction = null;
                if (x == 0 || x == w - 1 || y == 0 || y == h - 1)
                {
                    if ((y == 0 || y == h - 1) && x > 0 && x < w - 1)
                    {
                        canBeConnected = true;
                        direction = (y == 0) ? North : South;
                    }
                    else if ((x == 0 || x == w - 1) && y > 0 && y < h - 1)
                    {
                        canBeConnected = true;
                        direction = (x == 0) ? West : East;
                    }
                    tile = Wall;
                }
                else
                    tile = Floor;
                roomGrid.set(x, y, {tile: tile, canBeConnected: canBeConnected, direction: direction});
            }
        }
        return roomGrid;
    }
}
