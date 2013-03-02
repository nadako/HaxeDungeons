package dungeons.components;

class Item
{
    public var type(default, null):String;
    public var quantity:Int;
    private var stackable:Bool;

    public function new(type:String, stackable:Bool, quantity:Int)
    {
        this.type = type;
        this.stackable = stackable;
        this.quantity = quantity;
    }

    public function stacksWith(other:Item):Bool
    {
        if (stackable && other.type == type)
            return true;
        else
            return false;
    }
}
