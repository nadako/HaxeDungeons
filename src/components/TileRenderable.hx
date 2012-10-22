package components;

import Dungeon.Tile;

class TileRenderable
{
    public var tile(default, null):Tile;

    public function new(tile:Tile)
    {
        this.tile = tile;
    }
}
