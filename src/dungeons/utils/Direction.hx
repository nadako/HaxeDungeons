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
    public static function fromOffset(dx:Int, dy:Int):Direction
    {
        if (dx == 0)
        {
            if (dy < 0)
                return North;
            else if (dy > 0)
                return South;
        }
        else if (dy == 0)
        {
            if (dx < 0)
                return West;
            else if (dx > 0)
                return East;
        }
        else if (dy < 0 && dx < 0)
        {
            return NorthWest;
        }
        else if (dy < 0 && dx > 0)
        {
            return NorthEast;
        }
        else if (dy > 0 && dx < 0)
        {
            return SouthWest;
        }
        else if (dy > 0 && dx > 0)
        {
            return SouthEast;
        }

        throw "unknown direction for offset " + dx + "x" + dy;
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
