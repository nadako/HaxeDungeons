package dungeons.components;

import nme.display.DisplayObject;

import dungeons.render.RenderLayer;
import dungeons.render.IRenderer;

class Renderable
{
    public var renderer:IRenderer;
    public var layer:RenderLayer;
    public var animOffsetX:Int;
    public var animOffsetY:Int;

    public function new(layer:RenderLayer, renderer:IRenderer)
    {
        this.layer = layer;
        this.renderer = renderer;
    }
}
