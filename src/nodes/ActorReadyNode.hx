package nodes;

import net.richardlord.ash.core.Node;

import components.Behaviour;
import components.ActorReady;
import components.Actor;

class ActorReadyNode extends Node<ActorReadyNode>
{
    public var actor:Actor;
    public var ready:ActorReady;
    public var behaviour:Behaviour;
}
