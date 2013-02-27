package dungeons;

import com.haxepunk.Engine;
import com.haxepunk.HXP;

class Main extends Engine
{
    public function new()
    {
        super();
        HXP.world = new GameWorld();
    }
}
