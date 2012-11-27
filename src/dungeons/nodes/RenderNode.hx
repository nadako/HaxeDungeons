package dungeons.nodes;

import ash.core.Node;

import dungeons.components.Renderable;
import dungeons.components.Position;

class RenderNode extends Node<RenderNode>
{
    public var position:Position;
    public var renderable:Renderable;
}
