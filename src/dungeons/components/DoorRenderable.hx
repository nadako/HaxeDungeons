package dungeons.components;

import nme.display.DisplayObject;

import dungeons.render.RenderLayer;
import dungeons.render.IRenderer;

class DoorRenderable extends Renderable
{
    public var openRenderer:IRenderer;
    public var closedRenderer:IRenderer;

    public function new(openRenderer:IRenderer, closedRenderer:IRenderer)
    {
        this.openRenderer = openRenderer;
        this.closedRenderer = closedRenderer;
        super(RenderLayer.Dungeon, closedRenderer);
    }
}
