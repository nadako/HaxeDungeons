package components;

import nme.display.DisplayObject;

class Renderable
{
    public var displayObject(default, null):DisplayObject;

    public function new(displayObject:DisplayObject)
    {
        this.displayObject = displayObject;
    }
}
