package dungeons.systems;

import ash.signals.Signal2;
import ash.signals.Signal3;

class RenderSignals
{
    public var hpChange(default, null):Signal3<Int, Int, Int>;
    public var miss(default, null):Signal2<Int, Int>;

    public function new()
    {
        hpChange = new Signal3();
        miss = new Signal2();
    }
}
