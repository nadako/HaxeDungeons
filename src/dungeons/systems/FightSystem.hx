package dungeons.systems;

import ash.core.Engine;
import ash.core.Entity;
import ash.tools.ListIteratingSystem;
import ash.ObjectMap;

import dungeons.components.Position;
import dungeons.components.Fighter;
import dungeons.nodes.FighterNode;

using dungeons.utils.EntityUtil;

class FightSystem extends ListIteratingSystem<FighterNode>
{
    private var attackListeners:ObjectMap<FighterNode, AttackRequestListener>;
    private var engine:Engine;
    private var renderSignals:RenderSignals;

    public function new(renderSignals:RenderSignals)
    {
        super(FighterNode, null, onNodeAdded, onNodeRemoved);
        this.renderSignals = renderSignals;
    }

    override public function addToEngine(engine:Engine):Void
    {
        this.engine = engine;
        attackListeners = new ObjectMap();
        super.addToEngine(engine);
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        super.removeFromEngine(engine);
        for (node in attackListeners.keys())
            node.fighter.attackRequested.remove(attackListeners.get(node));
        attackListeners = null;
        this.engine = null;
    }

    private function onNodeAdded(node:FighterNode):Void
    {
        var listener = callback(onNodeAttackRequested, node);
        attackListeners.set(node, listener);
        node.fighter.attackRequested.add(listener);
    }

    private function onNodeAttackRequested(defender:FighterNode, attacker:Entity):Void
    {
        var attackerFighter:Fighter = attacker.get(Fighter);
        var defenderFighter:Fighter = defender.fighter;
        var defenderPos:Position = defender.entity.get(Position);

        var hit:Bool = Math.random() < attackerFighter.power / (attackerFighter.power + defenderFighter.defense);
        if (hit)
        {
            var damage:Int = Std.int(attackerFighter.power / (defender.fighter.defense > 0 ? defender.fighter.defense : 1));

            if (damage > 0)
            {
                defender.health.currentHP -= damage;

                if (defenderPos != null)
                    renderSignals.hpChange.dispatch(defenderPos.x, defenderPos.y, -damage);

                if (defender.health.currentHP <= 0)
                {
                    engine.removeEntity(defender.entity);

                    if (defender.entity.isPlayer())
                        MessageLogSystem.message("You die...");
                    else
                        MessageLogSystem.message(defender.entity.getName() + " dies.");
                }
            }
            else
            {
                if (defenderPos != null)
                    renderSignals.hpChange.dispatch(defenderPos.x, defenderPos.y, 0);
            }

            if (attacker.isPlayer())
                MessageLogSystem.message("You hit " + defender.entity.getName() + " for " + damage + " HP.");
            else if (defender.entity.isPlayer())
                MessageLogSystem.message(attacker.getName() + " hits you for " + damage + " HP.");
        }
        else
        {
            if (attacker.isPlayer())
                MessageLogSystem.message("You miss " + defender.entity.getName() + ".");
            else if (defender.entity.isPlayer())
                MessageLogSystem.message(attacker.getName() + " misses you.");

            if (defenderPos != null)
                renderSignals.miss.dispatch(defenderPos.x, defenderPos.y);
        }
    }

    private function onNodeRemoved(node:FighterNode):Void
    {
        var listener = attackListeners.get(node);
        attackListeners.remove(node);
        node.fighter.attackRequested.remove(listener);
    }
}
