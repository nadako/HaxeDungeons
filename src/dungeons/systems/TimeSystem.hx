package dungeons.systems;

import ash.ObjectMap;
import ash.tools.ListIteratingSystem;

import dungeons.nodes.TimeTickerNode;

class TimeSystem extends ListIteratingSystem<TimeTickerNode>
{
    private var listeners:ObjectMap<TimeTickerNode, Void -> Void>;

    public function new()
    {
        super(TimeTickerNode, null, onNodeAdded, onNodeRemoved);
        listeners = new ObjectMap();
    }

    private function onNodeAdded(node:TimeTickerNode):Void
    {
        var listener = callback(onTickActionRequested, node);
        node.actor.actionRequested.add(listener);
        listeners.set(node, listener);
    }

    private function onNodeRemoved(node:TimeTickerNode):Void
    {
        var listener = listeners.get(node);
        listeners.remove(node);
        node.actor.actionRequested.remove(listener);
    }

    private function onTickActionRequested(node:TimeTickerNode):Void
    {
        node.ticker.ticks++;
        node.actor.setAction(Wait);
    }
}
