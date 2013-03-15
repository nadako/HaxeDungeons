package dungeons;

import ru.stablex.ui.UIBuilder;

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

        UIBuilder.init();
    }
}
