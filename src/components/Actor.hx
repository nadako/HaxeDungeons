package components;

import Dungeon.Direction;

class Actor
{
    public var energy:Int;
    public var speed:Int;

    public function new(speed:Int)
    {
        this.speed = speed;
    }
}


enum Action
{
    Wait;
    Move(direction:Direction);
}
