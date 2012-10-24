package dungeons;

class ArrayUtil
{
    public static function randomChoice<T>(values:Array<T>):T
    {
        return values[Std.random(values.length)];
    }
}
