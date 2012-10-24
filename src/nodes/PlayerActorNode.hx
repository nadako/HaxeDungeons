package nodes;

import net.richardlord.ash.core.Node;

import components.PlayerControls;
import components.Actor;

class PlayerActorNode extends Node<PlayerActorNode>
{
    public var actor:Actor;
    public var controls:PlayerControls;
}
