package dungeons.systems;

import flash.Lib;
import nme.ObjectHash;

import ash.core.Engine;
import ash.core.Entity;
import ash.tools.ListIteratingSystem;

import dungeons.components.Fighter;
import dungeons.nodes.FighterNode;
using dungeons.EntityUtils;

class FightSystem extends ListIteratingSystem<FighterNode>
{
    private var attackListeners:ObjectHash<FighterNode, AttackRequestListener>;
    private var engine:Engine;

    public function new()
    {
        super(FighterNode, null, onNodeAdded, onNodeRemoved);
    }

    override public function addToEngine(engine:Engine):Void
    {
        this.engine = engine;
        attackListeners = new ObjectHash();
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

    private function onNodeAttackRequested(node:FighterNode, attacker:Entity):Void
    {
        var defenderFighter:Fighter = node.fighter;
        var attackerFighter:Fighter = attacker.get(Fighter);
        var damage:Int = attackerFighter.power - defenderFighter.defense;
        if (damage > 0)
        {
            defenderFighter.currentHP -= damage;

            if (attacker.isPlayer())
                MessageLogSystem.message("You hit " + node.entity.getName() + " for " + damage + " HP.");
            else if (node.entity.isPlayer())
                MessageLogSystem.message(attacker.getName() + " hits you for " + damage + " HP.");

            if (defenderFighter.currentHP <= 0)
            {
                engine.removeEntity(node.entity);

                if (node.entity.isPlayer())
                    MessageLogSystem.message("You die...");
                else
                    MessageLogSystem.message(node.entity.getName() + " dies.");
            }
        }
    }

    private function onNodeRemoved(node:FighterNode):Void
    {
        var listener = attackListeners.get(node);
        attackListeners.remove(node);
        node.fighter.attackRequested.remove(listener);
    }
}
