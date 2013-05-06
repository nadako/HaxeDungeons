package dungeons;

import com.haxepunk.gui.Control;
import com.haxepunk.Engine;
import com.haxepunk.HXP;

import dungeons.systems.RenderSystem.RenderLayers;

class Main extends Engine
{
    public function new()
    {
        super();
        Control.useSkin("gfx/ui/blueMagda.png");
        Control.defaultLayer = RenderLayers.UI;
//        HXP.console.enable();
        trace('Random seed is ${HXP.randomSeed}');
        HXP.scene = new GameScene();
    }

    override private function resize()
    {
        if (HXP.width == 0) HXP.width = HXP.stage.stageWidth;
        if (HXP.height == 0) HXP.height = HXP.stage.stageHeight;
        // calculate scale from width/height values
        HXP.screen.scaleX = 1;
        HXP.screen.scaleY = 1;
        HXP.resize(HXP.stage.stageWidth, HXP.stage.stageHeight);
    }
}
