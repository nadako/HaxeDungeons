package dungeons.systems;

import nme.ObjectHash;

import net.richardlord.ash.tools.ListIteratingSystem;
import net.richardlord.ash.core.System;
import net.richardlord.ash.core.Game;

import dungeons.Dungeon;
import dungeons.nodes.MonsterActorNode;

using dungeons.ArrayUtil;

class MonsterAISystem extends ListIteratingSystem<MonsterActorNode>
{
    private static inline var directions:Array<Direction> = [North, South, West, East];

    private var nodeListeners:ObjectHash<MonsterActorNode, Void->Void>;

    public function new()
    {
        super(MonsterActorNode, null, onNodeAdded, onNodeRemoved);
    }

    override public function addToGame(game:Game):Void
    {
        nodeListeners = new ObjectHash();
        super.addToGame(game);
    }

    override public function removeFromGame(game:Game):Void
    {
        super.removeFromGame(game);
        for (node in nodeListeners.keys())
            node.actor.actionRequested.remove(nodeListeners.get(node));
        nodeListeners = null;
    }

    private function onNodeAdded(node:MonsterActorNode):Void
    {
        var listener = callback(onNodeActionRequested, node);
        node.actor.actionRequested.add(listener);
        nodeListeners.set(node, listener);
    }

    private function onNodeActionRequested(node:MonsterActorNode):Void
    {
        node.actor.setAction(Move(directions.randomChoice()));
    }

    private function onNodeRemoved(node:MonsterActorNode):Void
    {
        var listener = nodeListeners.get(node);
        nodeListeners.remove(node);
        node.actor.actionRequested.remove(listener);
    }
}
