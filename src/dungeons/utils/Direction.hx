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
