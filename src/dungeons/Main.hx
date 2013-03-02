package dungeons;

import com.haxepunk.Engine;
import com.haxepunk.HXP;

class Main extends Engine
{
    public function new()
    {
        super();
        HXP.screen.scale = 4;
        HXP.console.enable();
        HXP.world = new GameWorld();
    }
}
