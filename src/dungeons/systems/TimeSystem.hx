package dungeons.systems;

import ash.tools.ListIteratingSystem;

import dungeons.nodes.TimeTickerNode;
import dungeons.utils.Scheduler;

class TimeSystem extends ListIteratingSystem<TimeTickerNode>
{
    private var scheduler:Scheduler;

    public function new(scheduler:Scheduler)
    {
        super(TimeTickerNode, null, onNodeAdded, onNodeRemoved);
        this.scheduler = scheduler;
    }

    private function onNodeAdded(node:TimeTickerNode):Void
    {
        scheduler.addActor(node.ticker);
    }

    private function onNodeRemoved(node:TimeTickerNode):Void
    {
        scheduler.removeActor(node.ticker);
    }
}
