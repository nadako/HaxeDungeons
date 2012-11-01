package dungeons.components;

import nme.display.DisplayObject;

import dungeons.render.IRenderer;

class Renderable
{
    public var renderer:IRenderer;

    public function new(renderer:IRenderer)
    {
        this.renderer = renderer;
    }
}
