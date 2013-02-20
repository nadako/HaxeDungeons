package dungeons;

using dungeons.ArrayUtil;

private typedef Vector =
{
    var x:Int;
    var y:Int;
}

class Dungeon
{
    public var width:Int;
    public var height:Int;
    public var maxRooms:Int;
    public var minRoomSize:Vector;
    public var maxRoomSize:Vector;

    public var doorChance:Float;
    public var openDoorChance:Float;

    public var grid(default, null):Grid<Tile>;
    public var rooms(default, null):Array<Room>;

    public function new(width:Int, height:Int, maxRooms:Int, minRoomSize:Vector, maxRoomSize:Vector, doorChance:Float = 0.75, openDoorChance:Float = 0.5)
    {
        this.width = width;
        this.height = height;
        this.maxRooms = maxRooms;
        this.minRoomSize = minRoomSize;
        this.maxRoomSize = maxRoomSize;
        this.doorChance = doorChance;
        this.openDoorChance = openDoorChance;
    }

    public function generate():Void
    {
        grid = new Grid<Tile>(width, height, Empty);
        rooms = new Array<Room>();

        var room:Room = generateRoom();
        var x:Int = Std.int((grid.width - room.grid.width) / 2);
        var y:Int = Std.int((grid.height - room.grid.height) / 2);
        placeRoom(room, x, y);

        var i:Int = 0;
        while (i < width * height * 2)
        {
            if (rooms.length == maxRooms)
                break;

            var connection:Connection = chooseConnection();
            room = generateRoom();

            switch (connection.direction)
            {
                case North:
                    x = connection.x - 1 - Std.random(room.grid.width - 2);
                    y = connection.y - room.grid.height;
                case South:
                    x = connection.x - 1 - Std.random(room.grid.width - 2);
                    y = connection.y + 1;
                case West:
                    x = connection.x - room.grid.width;
                    y = connection.y - 1 - Std.random(room.grid.height - 2);
                case East:
                    x = connection.x + 1;
                    y = connection.y - 1 - Std.random(room.grid.height - 2);
            }

            if (hasSpaceForRoom(room, x, y))
            {
                placeRoom(room, x, y);
                connectRooms(connection);
            }
            else
            {
                i++;
            }

            i++;
        }
    }

    public function getWallTransition(x:Int, y:Int):Int
    {
        var n = 1;
        var e = 2;
        var s = 4;
        var w = 8;
        var nw = 128;
        var ne = 16;
        var se = 32;
        var sw = 64;

        var v:Int = 0;
        if (isWallForTransition(x, y - 1))
            v |= n;
        if (isWallForTransition(x + 1, y))
            v |= e;
        if (isWallForTransition(x, y + 1))
            v |= s;
        if (isWallForTransition(x - 1, y))
            v |= w;
        if (isWallForTransition(x - 1, y - 1))
            v |= nw;
        if (isWallForTransition(x + 1, y - 1))
            v |= ne;
        if (isWallForTransition(x - 1, y + 1))
            v |= sw;
        if (isWallForTransition(x + 1, y + 1))
            v |= se;

        return v;
    }

    private inline function isWallForTransition(x:Int, y:Int):Bool
    {
        if (!grid.inRange(x, y))
        {
            return true;
        }
        else
        {
            var tile:Tile = grid.get(x, y);
            return tile == Wall || tile == Empty;
        }
    }

    private function generateRoom():Room
    {
        var w:Int = minRoomSize.x + Std.random(maxRoomSize.x - minRoomSize.x + 1);
        var h:Int = minRoomSize.y + Std.random(maxRoomSize.y - minRoomSize.y + 1);

        var roomGrid = new Grid(w, h);
        for (y in 0...h)
        {
            for (x in 0...w)
            {
                var tile:Tile;
                if (x == 0 || x == w - 1 || y == 0 || y == h - 1)
                    tile = Wall;
                else
                    tile = Floor;
                roomGrid.set(x, y, tile);
            }
        }
        return {grid: roomGrid, x: 0, y: 0};
    }

    private function chooseConnection():Connection
    {
        var room:Room = rooms.randomChoice();
        var direction:Direction = Type.allEnums(Direction).randomChoice();

        var x:Int;
        var y:Int;

        switch (direction)
        {
            case North:
                x = room.x + 1 + Std.random(room.grid.width - 2);
                y = room.y;
            case South:
                x = room.x + 1 + Std.random(room.grid.width - 2);
                y = room.y + room.grid.height - 1;
            case West:
                x = room.x;
                y = room.y + 1 + Std.random(room.grid.height - 2);
            case East:
                x = room.x + room.grid.width - 1;
                y = room.y + 1 + Std.random(room.grid.height - 2);
        }
        return {x: x, y: y, direction: direction};
    }

    private function hasSpaceForRoom(room:Room, x:Int, y:Int):Bool
    {
        for (gridY in y...y + room.grid.height)
        {
            for (gridX in x...x + room.grid.width)
            {
                if (!grid.inRange(gridX, gridY) || grid.get(gridX, gridY) != Empty)
                    return false;
            }
        }
        return true;
    }

    private function placeRoom(room:Room, x:Int, y:Int):Void
    {
        room.x = x;
        room.y = y;
        rooms.push(room);

        for (roomY in 0...room.grid.height)
        {
            for (roomX in 0...room.grid.width)
            {
                var tile:Tile = room.grid.get(roomX, roomY);
                if (tile != Empty)
                    grid.set(x + roomX, y + roomY, tile);
            }
        }
    }

    private function connectRooms(connection:Connection):Void
    {
        var posX:Int = connection.x;
        var posY:Int = connection.y;
        switch (connection.direction)
        {
            case North:
                posY--;
            case South:
                posY++;
            case West:
                posX--;
            case East:
                posX++;
        }

        var outerDoor:Bool = Math.random() < 0.5;
        var doorTile:Tile = (Math.random() < doorChance) ? Door(Math.random() < openDoorChance) : Floor;

        grid.set(connection.x, connection.y, outerDoor ? Floor : doorTile);
        grid.set(posX, posY, outerDoor ? doorTile : Floor);
    }
}

typedef Room =
{
    var x:Int;
    var y:Int;
    var grid:Grid<Tile>;
}

private typedef Connection =
{
    var x:Int;
    var y:Int;
    var direction:Direction;
}

enum Tile
{
    Empty;
    Wall;
    Floor;
    Door(open:Bool);
}

enum Direction
{
    North;
    South;
    West;
    East;
}

class Grid<T>
{
    public var width(default, null):Int;
    public var height(default, null):Int;

    private var content:Array<T>;

    public function new(width:Int, height:Int, fillValue:T = null)
    {
        this.width = width;
        this.height = height;

        content = [];
        for (i in 0...width * height)
            content.push(fillValue);
    }

    public function get(x:Int, y:Int):T
    {
        return content[y * width + x];
    }

    public function set(x:Int, y:Int, value:T):Void
    {
        content[y * width + x] = value;
    }

    public inline function inRange(x:Int, y:Int):Bool
    {
        return x >= 0 && x < width && y >= 0 && y < height;
    }
}
