package dungeons.nodes;

import net.richardlord.ash.core.Node;

import dungeons.components.LightSource;
import dungeons.components.Position;

class LightSourceNode extends Node<LightSourceNode>
{
    public var position:Position;
    public var lightSource:LightSource;
}
