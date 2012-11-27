package dungeons.nodes;

import ash.core.Node;

import dungeons.components.FOV;
import dungeons.components.Position;

class FOVNode extends Node<FOVNode>
{
    public var position:Position;
    public var fov:FOV;
}
