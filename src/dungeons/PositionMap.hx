package dungeons;

class PositionMap<T>
{
    private var width:Int;
    private var height:Int;
    private var content:Array<T>;

    public function new(width:Int, height:Int)
    {
        this.width = width;
        this.height = height;
        clear();
    }

    public inline function get(x:Int, y:Int):T
    {
        return content[y * width + x];
    }

    public inline function set(x:Int, y:Int, value:T):Void
    {
        content[y * width + x] = value;
    }

    public function clear():Void
    {
        content = [];
        for (i in 0...width * height)
            content.push(null);
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
        var value:Array<T> = get(x, y);
        if (value == null)
        {
            value = [];
            set(x, y, value);
        }
        return value;
    }
}
