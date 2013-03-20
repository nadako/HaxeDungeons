package dungeons.components;

import dungeons.systems.RenderSystem.RenderLayers;

class DoorRenderable extends Renderable
{
    public var openAssetName(default, null):String;
    public var closedAssetName(default, null):String;

    public function new(openAssetName:String, closedAssetName:String)
    {
        this.openAssetName = openAssetName;
        this.closedAssetName = closedAssetName;
        super(closedAssetName, RenderLayers.OBJECT);
    }

    public function setOpen(value:Bool):Void
    {
        assetName = value ? openAssetName : closedAssetName;
    }
}
