package dungeons.components;

import net.richardlord.ash.core.Entity;
import net.richardlord.signals.Signal0;

import dungeons.Dungeon.Direction;

class Actor
{
    public var energy:Int;
    public var speed:Int;

    public var awaitingAction(default, null):Bool;
    public var resultAction(default, null):Action;
    public var actionRequested(default, null):Signal0;

    public function new(speed:Int)
    {
        this.speed = speed;
        this.energy = speed;

        awaitingAction = false;
        resultAction = null;
        actionRequested = new Signal0();
    }

    public inline function requestAction():Void
    {
        awaitingAction = true;
        actionRequested.dispatch();
    }

    public inline function setAction(action:Action):Void
    {
        awaitingAction = false;
        resultAction = action;
    }

    public inline function clearAction():Void
    {
        resultAction = null;
    }
}


enum Action
{
    Wait;
    Move(direction:Direction);
    OpenDoor(door:Entity);
    Attack(defender:Entity);
}
