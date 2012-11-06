package dungeons;

class PositionMap<T>
{
    private var width:Int;
    private var height:Int;
    private var hash:IntHash<T>;

    public function new(width:Int, height:Int)
    {
        this.width = width;
        this.height = height;
        hash = new IntHash();
    }

    private inline function getKey(x:Int, y:Int):Int
    {
        return y * width + x;
    }

    public inline function get(x:Int, y:Int):T
    {
        if (x < 0 || x >= width || y < 0 || x >= height)
            return null;

        return hash.get(getKey(x, y));
    }

    public inline function set(x:Int, y:Int, value:T):Void
    {
        hash.set(getKey(x, y), value);
    }

    public function clear():Void
    {
        hash = new IntHash();
    }
}

class PositionArrayMap<T> extends PositionMap<Array<T>>
{
    public function new(width:Int, height:Int):Void
    {
        super(width, height);
    }

    public function getOrCreate(x:Int, y:Int):Array<T>
    {
        var value = get(x, y);
        if (value == null)
        {
            value = [];
            set(x, y, value);
        }
        return value;
    }
}
