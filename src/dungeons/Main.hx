package dungeons;

import com.bit101.components.Style;

import com.haxepunk.Engine;
import com.haxepunk.HXP;

import dungeons.systems.RenderSystem.RenderLayers;

class Main extends Engine
{
    public function new()
    {
        super();
//        HXP.console.enable();
        HXP.scene = new GameScene();

        Style.setStyle(Style.DARK);
    }
}
