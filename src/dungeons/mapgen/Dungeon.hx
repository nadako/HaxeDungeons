package dungeons.mapgen;

import dungeons.utils.Vector;
import dungeons.utils.Direction;
import dungeons.utils.Grid;

using dungeons.utils.ArrayUtil;

enum Tile
{
    Empty;
    Wall;
    Floor;
    Door(open:Bool, level:Int);
}

typedef Room =
{
    var x:Int;
    var y:Int;
    var grid:Grid<Tile>;
    var parent:Room;
    var children:Array<Room>;
    var level:Int;
    var unusedConnections:Array<Connection>;
    var connections:Array<Connection>;
}

private typedef Connection =
{
    var x:Int;
    var y:Int;
    var direction:Direction;
    var fromRoom:Room;
    var toRoom:Room;
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
    public var keyLevel(default, null):Int;

    private var levels:IntHash<Array<Room>>;
    private var connectionDirections:Array<Direction>;

    public function new(width:Int, height:Int, maxRooms:Int, minRoomSize:Vector, maxRoomSize:Vector, doorChance:Float = 0.75, openDoorChance:Float = 0.5)
    {
        this.width = width;
        this.height = height;
        this.maxRooms = maxRooms;
        this.minRoomSize = minRoomSize;
        this.maxRoomSize = maxRoomSize;
        this.doorChance = doorChance;
        this.openDoorChance = openDoorChance;

        connectionDirections = [North, West, South, East];
    }

    public function getLevelRooms(level:Int):Array<Room>
    {
        if (!levels.exists(level))
            levels.set(level, []);
        return levels.get(level);
    }

    private function useConnection(connection:Connection, toRoom:Room):Void
    {
        connection.fromRoom.unusedConnections.remove(connection);
        connection.fromRoom.connections.push(connection);
        connection.fromRoom.children.push(toRoom);
        connection.toRoom = toRoom;
        toRoom.parent = connection.fromRoom;
    }
    
    public function generate():Void
    {
        grid = new Grid<Tile>(width, height, Empty);
        rooms = [];
        levels = new IntHash();

        keyLevel = 0;
        var maxKeys:Int = 3;
        var roomsPerLock:Int = Std.int(maxRooms / maxKeys);

        var room:Room = generateRoom();
        var x:Int = Std.int((grid.width - room.grid.width) / 2);
        var y:Int = Std.int((grid.height - room.grid.height) / 2);
        placeRoom(room, x, y);

        var i:Int = 0;
        while (i < width * height * 2)
        {
            if (rooms.length == maxRooms)
                break;

            var doLock:Bool = false;
            if (getLevelRooms(keyLevel).length >= roomsPerLock)
            {
                keyLevel++;
                doLock = true;
            }

            var parentRoom:Room = null;
            if (!doLock)
                parentRoom = getLevelRooms(keyLevel).randomChoice();

            if (parentRoom == null)
            {
                parentRoom = rooms.randomChoice();
                doLock = true;
            }

            var connection:Connection = parentRoom.unusedConnections.randomChoice();
            room = generateRoom();
            room.level = keyLevel;

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
                default:
            }

            if (hasSpaceForRoom(room, x, y))
            {
                placeRoom(room, x, y);
                connectRoom(connection, room, doLock);
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
        return {grid: roomGrid, x: 0, y: 0, parent: null, children: [], level: 0, connections: [], unusedConnections: []};
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
        getLevelRooms(room.level).push(room);

        for (roomY in 0...room.grid.height)
        {
            for (roomX in 0...room.grid.width)
            {
                var tile:Tile = room.grid.get(roomX, roomY);
                if (tile != Empty)
                    grid.set(x + roomX, y + roomY, tile);

                if (roomY == 0 && roomX > 0 && roomX < room.grid.width - 2)
                    room.unusedConnections.push({x: x + roomX, y: y + roomY, direction: North, fromRoom: room, toRoom: null});
                else if (roomY == room.grid.height - 1 && roomX > 0 && roomX < room.grid.width - 2)
                    room.unusedConnections.push({x: x + roomX, y: y + roomY, direction: South, fromRoom: room, toRoom: null});
                else if (roomX == 0 && roomY > 0 && roomY < room.grid.height - 2)
                    room.unusedConnections.push({x: x + roomX, y: y + roomY, direction: West, fromRoom: room, toRoom: null});
                else if (roomX == room.grid.width - 1 && roomY > 0 && roomY < room.grid.height - 2)
                    room.unusedConnections.push({x: x + roomX, y: y + roomY, direction: East, fromRoom: room, toRoom: null});
            }
        }
    }

    private function connectRoom(connection:Connection, room:Room, lock:Bool):Void
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
            default:
                throw "invalid direction";
        }

        var outerDoor:Bool = Math.random() < 0.5;

        var doorTile:Tile = Floor;
        if (lock)
            doorTile = Door(false, room.level);
        else if (Math.random() < doorChance)
            doorTile = Door(Math.random() < openDoorChance, 0);

        grid.set(connection.x, connection.y, outerDoor ? Floor : doorTile);
        grid.set(posX, posY, outerDoor ? doorTile : Floor);

        if (room.parent != null)
            throw "Room parent is already set? WTF!";

        useConnection(connection, room);
    }
}
