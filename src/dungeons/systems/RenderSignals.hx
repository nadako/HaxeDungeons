package dungeons.systems;

import ash.signals.Signal3;

class RenderSignals
{
    public var hpChange(default, null):Signal3<Int, Int, Int>;

    public function new()
    {
        hpChange = new Signal3();
    }
}
