package components;

import Dungeon.Direction;

class Actor
{
    public var energy:Int;
    public var speed:Int;

    public var awaitingAction:Bool;
    public var resultAction:Action;

    public function new(speed:Int)
    {
        this.speed = speed;
        this.energy = speed;

        awaitingAction = false;
        resultAction = null;
    }
}


enum Action
{
    Wait;
    Move(direction:Direction);
}
