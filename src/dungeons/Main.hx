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
//        HXP.console.enable();
        HXP.world = new GameWorld();

        Control.useSkin("gfx/ui/blueMagda.png");
        Control.defaultLayer = RenderLayers.UI;
    }
}
