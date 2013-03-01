package dungeons.utils;

// enable these classes with "using ArrayUtil"

class ArrayUtil
{
    public static function randomChoice<T>(array:Array<T>):T
    {
        return array[Std.random(array.length)];
    }
}

class EnumUtil
{
    public static function randomChoice<T>(e:Enum<T>):T
    {
        return ArrayUtil.randomChoice(Type.allEnums(e));
    }
}
