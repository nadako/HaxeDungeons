package nodes;

import net.richardlord.ash.core.Node;

import components.PlayerControls;
import components.Position;

class PlayerNode extends Node<PlayerNode>
{
    public var position:Position;
    public var controls:PlayerControls;
}
