package systems;

import de.polygonal.ds.ArrayedDeque;

import net.richardlord.ash.tools.ComponentPool;
import net.richardlord.ash.core.NodeList;
import net.richardlord.ash.core.Game;
import net.richardlord.ash.core.System;

import nodes.ActorNode;
import components.ActorReady;
import components.Actor;

class ActorRefreshSystem extends System
{
    private var nodes:NodeList<ActorNode>;
    private var queue:ArrayedDeque<ActorNode>;

    override public function addToGame(game:Game):Void
    {
        nodes = game.getNodeList(ActorNode);
        for (node in nodes)
            onNodeAdded(node);
        nodes.nodeAdded.add(onNodeAdded);
        nodes.nodeRemoved.add(onNodeRemoved);
    }

    override public function removeFromGame(game:Game):Void
    {
        nodes.nodeAdded.remove(onNodeAdded);
        nodes.nodeRemoved.remove(onNodeRemoved);
        game.releaseNodeList(ActorNode);
        nodes = null;
    }

    private function onNodeAdded(node:ActorNode):Void
    {
        queue.pushBack(node);
    }

    private function onNodeRemoved(node:ActorNode):Void
    {
        queue.remove(node);
    }

    override public function update(time:Float):Void
    {
        if (queue.size() > 0)
        {
            var node:ActorNode = queue.popFront();
            queue.pushBack(node);

            node.actor.energy += node.actor.speed;
            if (node.actor.energy > 0)
                node.entity.add(ComponentPool.get(ActorReady));
        }
    }
}
