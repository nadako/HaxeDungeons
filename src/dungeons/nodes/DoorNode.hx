package dungeons.nodes;

import ash.core.Node;

import dungeons.components.Door;
import dungeons.components.Position;

class DoorNode extends Node<DoorNode>
{
    public var door:Door;
    public var position:Position;
}
