package dungeons.utils;

enum Direction
{
    North;
    NorthEast;
    East;
    SouthEast;
    South;
    SouthWest;
    West;
    NorthWest;
}

class DirectionUtil
{
    public static inline function fromOffset(dx:Int, dy:Int):Direction
    {
        return if (dx == 0)
        {
            if (dy < 0)
                North;
            else if (dy > 0)
                South;
        }
        else if (dy == 0)
        {
            if (dx < 0)
                West;
            else if (dx > 0)
                East;
        }
        else if (dy < 0 && dx < 0)
        {
            NorthWest;
        }
        else if (dy < 0 && dx > 0)
        {
            NorthEast;
        }
        else if (dy > 0 && dx < 0)
        {
            SouthWest;
        }
        else if (dy > 0 && dx > 0)
        {
            SouthEast;
        }
        else
        {
            throw "unknown direction for offset " + dx + "x" + dy;
        }
    }

    public static inline function offset(dir:Direction):Vector
    {
        var x:Int = 0;
        var y:Int = 0;

        switch (dir)
        {
            case North:
                y--;
            case NorthEast:
                y--;
                x++;
            case East:
                x++;
            case SouthEast:
                x++;
                y++;
            case South:
                y++;
            case SouthWest:
                x--;
                y++;
            case West:
                x--;
            case NorthWest:
                x--;
                y--;
        }

        return {x: x, y: y};
    }

    public static inline function isDiagonal(dir:Direction):Bool
    {
        return switch (dir)
        {
            case North, West, South, East:
                false;
            default:
                true;
        };
    }
}
