package nodes;

import net.richardlord.ash.core.Node;

import components.Move;
import components.Position;

class MoveNode extends Node<MoveNode>
{
    public var position:Position;
    public var move:Move;
}
