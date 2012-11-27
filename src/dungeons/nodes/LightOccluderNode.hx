package dungeons.nodes;

import ash.core.Node;

import dungeons.components.LightOccluder;
import dungeons.components.Position;

class LightOccluderNode extends Node<LightOccluderNode>
{
    public var position:Position;
    public var occluder:LightOccluder;
}
