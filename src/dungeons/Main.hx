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
        Control.useSkin("blueMagda.png");
        Control.defaultLayer = RenderLayers.UI;
//        HXP.console.enable();
        trace(Std.format("Random seed is ${HXP.randomSeed}"));
        HXP.scene = new GameScene();
    }
}
