package dungeons.nodes;

import net.richardlord.ash.core.Node;

import dungeons.components.TileRenderable;
import dungeons.components.Position;

class DungeonTileNode extends Node<DungeonTileNode>
{
    public var position:Position;
    public var renderable:TileRenderable;
}
