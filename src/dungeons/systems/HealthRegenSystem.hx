package dungeons.systems;

import dungeons.components.Position;
import ash.tools.ListIteratingSystem;

import dungeons.nodes.HealthRegenNode;
import dungeons.utils.Scheduler;

class HealthRegenSystem extends ListIteratingSystem<HealthRegenNode>
{
    private var listeners:Map<HealthRegenNode, Void->Void>;
    private var scheduler:Scheduler;
    private var renderSignals:RenderSignals;

    public function new(scheduler:Scheduler, renderSignals:RenderSignals)
    {
        super(HealthRegenNode, null, onNodeAdd, onNodeRemove);
        this.scheduler = scheduler;
        this.renderSignals = renderSignals;
        listeners = new Map<HealthRegenNode, Void->Void>();
    }

    private function onNodeAdd(node:HealthRegenNode):Void
    {
        scheduler.addActor(node.regen);
        var listener:Void->Void = onNodeRegenTick.bind(node);
        listeners.set(node, listener);
        node.regen.regenTick.add(listener);
    }

    private function onNodeRemove(node:HealthRegenNode):Void
    {
        var listener:Void->Void = listeners.get(node);
        listeners.remove(node);
        node.regen.regenTick.remove(listener);
        scheduler.removeActor(node.regen);
    }

    private function onNodeRegenTick(node:HealthRegenNode):Void
    {
        if (node.health.currentHP < node.health.maxHP)
        {
            node.health.currentHP += 1;
            var pos:Position = node.entity.get(Position);
            if (pos != null)
                renderSignals.hpChange.dispatch(pos.x, pos.y, 1);
        }
    }
}
