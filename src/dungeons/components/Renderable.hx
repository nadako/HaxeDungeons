package dungeons.components;

import com.haxepunk.HXP;
import com.haxepunk.Graphic;

import dungeons.systems.RenderSystem.RenderLayers;

class Renderable
{
    public var assetName(default, set_assetName):String;
    public var assetInvalid:Bool;
    public var layer(default, null):Int;
    public var memorable:Bool;

    public function new(assetName:String, layer:Int = RenderLayers.DUNGEON, memorable:Bool = true)
    {
        this.layer = layer;
        this.memorable = memorable;
        this.assetName = assetName;
    }

    private inline function set_assetName(value:String):String
    {
        if (assetName != value)
        {
            assetName = value;
            assetInvalid = true;
        }
        return value;
    }
}
