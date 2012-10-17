package ;

import de.polygonal.core.math.random.Random;
import de.polygonal.ds.Array2;

using ArrayUtil;

class Dungeon
{
    public var size:Array2Cell;
    public var maxRooms:Int;
    public var minRoomSize:Array2Cell;
    public var maxRoomSize:Array2Cell;

    public var grid(default, null):Array2<Tile>;
    public var rooms(default, null):Array<Room>;

    public function new(size:Array2Cell, maxRooms:Int, minRoomSize:Array2Cell, maxRoomSize:Array2Cell)
    {
        this.size = size;
        this.maxRooms = maxRooms;
        this.minRoomSize = minRoomSize;
        this.maxRoomSize = maxRoomSize;
    }

    public function generate():Void
    {
        grid = new Array2<Tile>(size.x, size.y);
        grid.fill(Empty);

        rooms = new Array<Room>();

        var room:Room = generateRoom();
        var roomPos:Array2Cell = new Array2Cell(Std.int((grid.getW() - room.grid.getW()) / 2), Std.int((grid.getH() - room.grid.getH()) / 2));
        placeRoom(room, roomPos);

        var i:Int = 0;
        while (i < grid.size() * 2)
        {
            if (rooms.length == maxRooms)
                break;

            room = generateRoom();
            roomPos = new Array2Cell();

            var connection:Connection = chooseConnection();
            switch (connection.direction)
            {
                case North:
                    roomPos.x = connection.position.x - Random.randRange(1, room.grid.getW() - 2);
                    roomPos.y = connection.position.y - room.grid.getH();
                case South:
                    roomPos.x = connection.position.x - Random.randRange(1, room.grid.getW() - 2);
                    roomPos.y = connection.position.y + 1;
                case West:
                    roomPos.x = connection.position.x - room.grid.getW();
                    roomPos.y = connection.position.y - Random.randRange(1, room.grid.getH() - 2);
                case East:
                    roomPos.x = connection.position.x + 1;
                    roomPos.y = connection.position.y - Random.randRange(1, room.grid.getH() - 2);
            }

            if (hasSpaceForRoom(room, roomPos))
            {
                placeRoom(room, roomPos);
                connectRooms(connection);
            }
            else
            {
                i++;
            }

            i++;
        }
    }

    private function generateRoom():Room
    {
        var roomGrid = new Array2(Random.randRange(minRoomSize.x, maxRoomSize.x), Random.randRange(minRoomSize.y, maxRoomSize.y));
        for (y in 0...roomGrid.getH())
        {
            for (x in 0...roomGrid.getW())
            {
                var tile:Tile;
                if (x == 0 || x == roomGrid.getW() - 1 || y == 0 || y == roomGrid.getH() - 1)
                    tile = Wall;
                else
                    tile = Floor;
                roomGrid.set(x, y, tile);
            }
        }
        return {grid: roomGrid, position: null};
    }

    private function chooseConnection():Connection
    {
        var room:Room = rooms.randomChoice();
        var direction:Direction = Type.allEnums(Direction).randomChoice();
        var position:Array2Cell = new Array2Cell();
        switch (direction)
        {
            case North:
                position.x = room.position.x + 1 + Std.random(room.grid.getW() - 2);
                position.y = room.position.y;
            case South:
                position.x = room.position.x + 1 + Std.random(room.grid.getW() - 2);
                position.y = room.position.y + room.grid.getH() - 1;
            case West:
                position.x = room.position.x;
                position.y = room.position.y + 1 + Std.random(room.grid.getH() - 2);
            case East:
                position.x = room.position.x + room.grid.getW() - 1;
                position.y = room.position.y + 1 + Std.random(room.grid.getH() - 2);
        }
        return {direction: direction, position: position};
    }

    private function hasSpaceForRoom(room:Room, position:Array2Cell):Bool
    {
        for (y in position.y...position.y + room.grid.getH())
        {
            for (x in position.x...position.x + room.grid.getW())
            {
                if (!grid.inRange(x, y) || grid.get(x, y) != Empty)
                    return false;
            }
        }
        return true;
    }

    private function placeRoom(room:Room, position:Array2Cell):Void
    {
        room.position = position;
        rooms.push(room);

        for (y in 0...room.grid.getH())
        {
            for (x in 0...room.grid.getW())
            {
                var tile:Tile = room.grid.get(x, y);
                if (tile != Empty)
                    grid.set(position.x + x, position.y + y, tile);
            }
        }
    }

    private function connectRooms(connection:Connection):Void
    {
        grid.set(connection.position.x, connection.position.y, Floor);

        switch (connection.direction)
        {
            case North:
                grid.set(connection.position.x, connection.position.y - 1, Floor);
            case South:
                grid.set(connection.position.x, connection.position.y + 1, Floor);
            case West:
                grid.set(connection.position.x - 1, connection.position.y, Floor);
            case East:
                grid.set(connection.position.x + 1, connection.position.y, Floor);
        }
    }
}

typedef Room = {
    var grid:Array2<Tile>;
    var position:Array2Cell;
}

typedef Connection = {
    var position:Array2Cell;
    var direction:Direction;
}

enum Tile
{
    Empty;
    Wall;
    Floor;
}

enum Direction
{
    North;
    South;
    West;
    East;
}