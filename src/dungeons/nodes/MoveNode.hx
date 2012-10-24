package dungeons.nodes;

import net.richardlord.ash.core.Node;

import dungeons.components.Move;
import dungeons.components.Position;

class MoveNode extends Node<MoveNode>
{
    public var position:Position;
    public var move:Move;
}
