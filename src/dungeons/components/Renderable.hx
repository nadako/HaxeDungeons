package dungeons.components;

import nme.display.DisplayObject;

import dungeons.render.IRenderer;

class Renderable
{
    public var renderer:IRenderer;
    public var animOffsetX:Int;
    public var animOffsetY:Int;

    public function new(renderer:IRenderer)
    {
        this.renderer = renderer;
    }
}
