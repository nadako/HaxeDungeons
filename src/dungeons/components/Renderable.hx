package dungeons.components;

import com.haxepunk.HXP;
import com.haxepunk.Graphic;

class Renderable
{
    public var graphic(default, null):Graphic;
    public var layer(default, null):Int;

    public function new(graphic:Graphic, layer:Int = HXP.BASELAYER)
    {
        this.graphic = graphic;
        this.layer = layer;
    }
}
