package systems;

import net.richardlord.ash.tools.ListIteratingSystem;

import nodes.ActorReadyNode;
import components.Actor;

class ActorProcessSystem extends ListIteratingSystem<ActorReadyNode>
{
    public function new()
    {
        super(ActorReadyNode, processNode);
    }

    private function processNode(node:ActorReadyNode, dt:Float):Void
    {
        var action:Action;
        switch (node.behaviour.type)
        {
            case Player:
                action = processPlayer(node);
        }
    }

    private function processPlayer():Action
    {
        return Wait;
    }
}
