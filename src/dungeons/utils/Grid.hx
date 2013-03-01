package dungeons.utils;

/**
 * Generic 2D fixed-size grid.
 **/
class Grid<T>
{
    public var width(default, null):Int;
    public var height(default, null):Int;

    private var content:Array<T>;

    public function new(width:Int, height:Int, fillValue:T = null)
    {
        this.width = width;
        this.height = height;
        clear(fillValue);
    }

    public inline function get(x:Int, y:Int):T
    {
        return content[y * width + x];
    }

    public inline function set(x:Int, y:Int, value:T):Void
    {
        content[y * width + x] = value;
    }

    public inline function inRange(x:Int, y:Int):Bool
    {
        return x >= 0 && x < width && y >= 0 && y < height;
    }

    public function clear(fillValue:T = null):Void
    {
        content = [];
        for (i in 0...width * height)
            content.push(fillValue);
    }
}
