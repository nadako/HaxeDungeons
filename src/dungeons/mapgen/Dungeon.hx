package dungeons.mapgen;

import Lambda;

import ash.ObjectMap;

import com.haxepunk.HXP;

import dungeons.mapgen.IRoomFactory.RoomCellInfo;
import dungeons.utils.Vector;
import dungeons.utils.Direction;
import dungeons.utils.Grid;

using dungeons.utils.ArrayUtil;
using dungeons.utils.Direction.DirectionUtil;

enum Tile
{
    Empty;
    Wall;
    Floor;
    Door(open:Bool, level:Int);
}

typedef CellInfo =
{
    var tile:Tile;
    var room:Room;
}

typedef Room =
{
    var x:Int;
    var y:Int;
    var grid:Grid<RoomCellInfo>;
    var parent:Room;
    var children:Array<Room>;
    var level:Int;
    var unusedConnections:Array<Connection>;
    var connections:Array<Connection>;
    var intensity:Float;
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

    public var doorChance:Float;
    public var openDoorChance:Float;

    public var grid(default, null):Grid<CellInfo>;
    public var rooms(default, null):Array<Room>;
    public var keyLevel(default, null):Int;

    private var levels:IntHash<Array<Room>>;
    private var connectionDirections:Array<Direction>;
    private var roomFactory:IRoomFactory;

    public function new(width:Int, height:Int, maxRooms:Int, minRoomSize:Vector, maxRoomSize:Vector, doorChance:Float = 0.75, openDoorChance:Float = 0.5)
    {
        this.width = width;
        this.height = height;
        this.maxRooms = maxRooms;
        this.doorChance = doorChance;
        this.openDoorChance = openDoorChance;
        this.roomFactory = new RectRoomFactory(minRoomSize, maxRoomSize);

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
        grid = new Grid<CellInfo>(width, height);
        for (y in 0...grid.height)
        {
            for (x in 0...grid.width)
            {
                grid.set(x, y, {tile: Empty, room: null});
            }
        }
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
                    x = connection.x - 1 - HXP.rand(room.grid.width - 2);
                    y = connection.y - room.grid.height;
                case South:
                    x = connection.x - 1 - HXP.rand(room.grid.width - 2);
                    y = connection.y + 1;
                case West:
                    x = connection.x - room.grid.width;
                    y = connection.y - 1 - HXP.rand(room.grid.height - 2);
                case East:
                    x = connection.x + 1;
                    y = connection.y - 1 - HXP.rand(room.grid.height - 2);
                default:
            }

            if (hasSpaceForRoom(room, x, y))
            {
                placeRoom(room, x, y);
                connectRoom(connection, room, doLock ? room.level : 0);
                useConnection(connection, room);
            }
            else
            {
                i++;
            }

            i++;
        }

        addLoops();
        calcIntensity();
    }

    private function traceToRoom(connection:Connection)
    {
        var offset:Vector = connection.direction.offset();
        var x:Int = connection.x;
        var y:Int = connection.y;

        for (_ in 0...7)
        {
            x += offset.x;
            y += offset.y;

            if (!grid.inRange(x, y))
                return null;

            var room:Room = grid.get(x, y).room;
            if (room != null)
                return {x: x, y: y, room: room};
        }

        return null;
    }

    private function addLoops():Void
    {
        for (room in rooms)
        {
            var connectedRooms:ObjectMap<Room, Bool> = new ObjectMap();
            for (conn in room.connections)
                connectedRooms.set(conn.toRoom, true);

            for (conn in room.unusedConnections)
            {
                var nextRoomInfo:{var x:Int; var y:Int; var room:Room;} = traceToRoom(conn);
                if (nextRoomInfo == null || connectedRooms.exists(nextRoomInfo.room))
                    continue;

                var nextRoom:Room = nextRoomInfo.room;
                var pos:Vector = nextRoomInfo;

                var roomCellInfo:RoomCellInfo = nextRoom.grid.get(pos.x - nextRoom.x, pos.y - nextRoom.y);
                if (!roomCellInfo.canBeConnected)
                    continue;

                var hasConnection:Bool = false;
                for (nextRoomConn in nextRoom.connections)
                {
                    if (nextRoomConn.toRoom == room)
                    {
                        hasConnection = true;
                        break;
                    }
                }

                if (hasConnection)
                    continue;

                if (room.level == nextRoom.level)
                {
//                    trace("Adding loop connection");
                    makeCorridor(conn, pos);
                    connectRoom(conn, nextRoom, 0);
                    connectedRooms.set(nextRoom, true);
                    conn.toRoom = nextRoom;
                    room.connections.push(conn);
                }
                else if (Math.abs(room.level - nextRoom.level) == 1)
                {
//                    trace("Adding locked loop connection");
                    makeCorridor(conn, pos);
                    connectRoom(conn, nextRoom, Std.int(Math.max(room.level, nextRoom.level)));
                    connectedRooms.set(nextRoom, true);
                    conn.toRoom = nextRoom;
                    room.connections.push(conn);
                }
            }
        }
    }

    private function makeCorridor(connection:Connection, endPos:Vector):Void
    {
        var offset:Vector = connection.direction.offset();
        var x:Int = connection.x;
        var y:Int = connection.y;

        var l:Int = switch (connection.direction)
        {
            case North, South:
                endPos.y - connection.y;
            case East, West:
                endPos.x - connection.x;
            default:
                0;
        };
        var length:Int = Std.int(Math.abs(l));

        while (length > 0)
        {
            x += offset.x;
            y += offset.y;
            length--;

            grid.get(x, y).tile = Floor;

            switch (connection.direction)
            {
                case North, South:
                    setWallIfEmpty(x - 1, y);
                    setWallIfEmpty(x + 1, y);
                case East, West:
                    setWallIfEmpty(x, y - 1);
                    setWallIfEmpty(x, y + 1);
                default:
            }

        }
    }

    private inline function setWallIfEmpty(x:Int, y:Int):Void
    {
        var cell:CellInfo = grid.get(x, y);
        if (cell.tile == Empty)
            cell.tile = Wall;
    }

    private function calcIntensity():Void
    {
        var INTENSITY_EASE_OFF:Float = 0.2;

        var keys:Array<Int> = [];
        for (key in levels.keys())
            keys.push(key);

        keys.sort(function(a, b) { return a - b; });

        var nextLevelBaseIntensity:Float = 0.0;
        for (key in keys)
        {
            var intensity:Float = nextLevelBaseIntensity * (1.0 - INTENSITY_EASE_OFF);
            for (room in levels.get(key))
            {
                if (room.parent == null || room.parent.level < room.level)
                    nextLevelBaseIntensity = Math.max(nextLevelBaseIntensity, applyIntensity(room, intensity));
            }
        }

        // normalize
        var maxIntensity:Float = 0.0;
        for (room in rooms)
            maxIntensity = Math.max(maxIntensity, room.intensity);
        for (room in rooms)
            room.intensity = room.intensity * 0.99 / maxIntensity;
    }

    private function applyIntensity(room:Room, intensity:Float):Float
    {
        var INTENSITY_GROWTH_JITTER:Float = 0.1;
        intensity *= 1.0 - INTENSITY_GROWTH_JITTER/2.0 + INTENSITY_GROWTH_JITTER * HXP.random;

        room.intensity = intensity;

        var maxIntensity:Float = intensity;
        for (child in room.children)
        {
            if (room.level == child.level)
                maxIntensity = Math.max(maxIntensity, applyIntensity(child, intensity + 1.0));
        }
        return maxIntensity;
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
            var tile:Tile = grid.get(x, y).tile;
            return tile == Wall || tile == Empty;
        }
    }

    private function generateRoom():Room
    {
        return {
            grid: roomFactory.generateRoomGrid(),
            x: 0, y: 0,
            parent: null,
            children: [],
            level: 0,
            connections: [],
            unusedConnections: [],
            intensity: 0
        };
    }

    private function hasSpaceForRoom(room:Room, x:Int, y:Int):Bool
    {
        for (gridY in y...y + room.grid.height)
        {
            for (gridX in x...x + room.grid.width)
            {
                if (!grid.inRange(gridX, gridY) || grid.get(gridX, gridY).tile != Empty)
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
                var roomCell:RoomCellInfo = room.grid.get(roomX, roomY);
                if (roomCell.tile != Empty)
                {
                    var cell:CellInfo = grid.get(x + roomX, y + roomY);
                    cell.tile = roomCell.tile;
                    cell.room = room;
                }
                if (roomCell.canBeConnected)
                    room.unusedConnections.push({x: x + roomX, y: y + roomY, direction: roomCell.direction, fromRoom: room, toRoom: null});
            }
        }
    }

    private function getConnectionNextPos(connection:Connection):Vector
    {
        var offset:Vector = connection.direction.offset();
        return {x: connection.x + offset.x, y: connection.y + offset.y};
    }
    
    private function connectRoom(connection:Connection, room:Room, lockLevel:Int):Void
    {
        var pos:Vector = getConnectionNextPos(connection);

        var outerDoor:Bool = HXP.random < 0.5;

        var doorTile:Tile = Floor;
        if (lockLevel > 0)
            doorTile = Door(false, lockLevel);
        else if (HXP.random < doorChance)
            doorTile = Door(HXP.random < openDoorChance, 0);

        grid.get(connection.x, connection.y).tile = outerDoor ? Floor : doorTile;
        grid.get(pos.x, pos.y).tile = outerDoor ? doorTile : Floor;
    }
}
