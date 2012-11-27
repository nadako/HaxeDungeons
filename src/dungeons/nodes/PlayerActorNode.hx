package dungeons.nodes;

import ash.core.Node;

import dungeons.components.PlayerControls;
import dungeons.components.Actor;

class PlayerActorNode extends Node<PlayerActorNode>
{
    public var actor:Actor;
    public var controls:PlayerControls;
}
