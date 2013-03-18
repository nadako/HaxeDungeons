package dungeons.components;

import com.haxepunk.HXP;
import com.haxepunk.Graphic;

import dungeons.systems.RenderSystem.RenderLayers;

class Renderable
{
    public var graphic(default, null):Graphic;
    public var layer(default, null):Int;
    public var memorable:Bool;

    public function new(graphic:Graphic, layer:Int = RenderLayers.DUNGEON, memorable:Bool = true)
    {
        this.graphic = graphic;
        this.layer = layer;
        this.memorable = memorable;
    }
}
