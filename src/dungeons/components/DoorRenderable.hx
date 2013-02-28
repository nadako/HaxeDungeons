package dungeons.components;

import dungeons.systems.RenderSystem.RenderLayers;
import com.haxepunk.graphics.Graphiclist;
import com.haxepunk.Graphic;

class DoorRenderable extends Renderable
{
    public var openGraphic:Graphic;
    public var closedGraphic:Graphic;

    public function new(openGraphic:Graphic, closedGraphic:Graphic)
    {
        this.openGraphic = openGraphic;
        this.closedGraphic = closedGraphic;
        super(new Graphiclist([openGraphic, closedGraphic]), RenderLayers.OBJECT);
    }

    public function setOpen(value:Bool):Void
    {
        openGraphic.visible = value;
        closedGraphic.visible = !value;
    }
}
