package dungeons.components;

import dungeons.Dungeon.Direction;

class Move
{
    public var direction:Direction;

    public function new(direction:Direction = null)
    {
        this.direction = direction;
    }
}
