package dungeons.systems;

import com.haxepunk.utils.Key;
import com.haxepunk.utils.Input;

import ash.core.Entity;
import ash.core.Engine;
import ash.core.NodeList;
import ash.core.System;

import dungeons.components.Actor;
import dungeons.components.Door;
import dungeons.components.Position;
import dungeons.nodes.PlayerActorNode;
import dungeons.utils.Direction;

class PlayerControlSystem extends System
{
    private var obstacleSystem:ObstacleSystem;
    private var nodeList:NodeList<PlayerActorNode>;
    private var inputHandler:IInputHandler;

    public function new()
    {
        super();
    }

    override public function addToEngine(engine:Engine):Void
    {
        nodeList = engine.getNodeList(PlayerActorNode);
        obstacleSystem = engine.getSystem(ObstacleSystem);
        inputHandler = new MainInputHandler();
        inputHandler.enter();
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        obstacleSystem = null;
        nodeList = null;
        inputHandler.exit();
        inputHandler = null;
    }

    private function getAction(entity:Entity):Action
    {
        var action:Action = inputHandler.processKey(Input.lastKey);

        if (action != null && Type.enumConstructor(action) == "Move")
            action = processMove(entity, action);

        return action;
    }

    private function processMove(entity:Entity, moveAction:Action):Action
    {
        var direction:Direction = Type.enumParameters(moveAction)[0];
        var position:Position = entity.get(Position);
        if (position != null)
        {
            var targetTile = position.getAdjacentTile(direction);
            var blocker:Entity = obstacleSystem.getBlocker(targetTile.x, targetTile.y);
            if (blocker != null)
            {
                if (blocker.has(dungeons.components.Door))
                    return OpenDoor(blocker);
                if (blocker.has(dungeons.components.Fighter))
                    return Attack(blocker);
            }
        }
        return moveAction;
    }

    override public function update(time:Float):Void
    {
        if (Input.pressed(Key.ANY))
        {
            for (node in nodeList)
            {
                if (node.actor.awaitingAction)
                {
                    var action = getAction(node.entity);
                    if (action != null)
                        node.actor.setAction(action);
                }
            }
        }
    }
}

interface IInputHandler
{
    function enter():Void;
    function exit():Void;
    function processKey(key:Int):Action;
}

class InputHandlerBase implements IInputHandler
{
    private var next:IInputHandler;

    public function enter():Void
    {
    }

    public function exit():Void
    {
    }

    public function processKey(key:Int):Action
    {
        if (next != null)
            return next.processKey(key);
        else
            return handleKey(key);
    }

    private function pushHandler(handler:IInputHandler):Void
    {
        if (next != null)
            throw "Already have next handler " + handler;
        next = handler;
        next.enter();
    }

    private function popHandler():Void
    {
        next.exit();
        next = null;
    }

    private function handleKey(key:Int):Action
    {
        return null;
    }
}

class MainInputHandler extends InputHandlerBase
{
    public function new()
    {
    }

    override private function handleKey(key:Int):Action
    {
        var action:Action = null;
        switch (key)
        {
            case Key.UP, Key.NUMPAD_8:
                action = Move(North);
            case Key.NUMPAD_7:
                action = Move(NorthWest);
            case Key.NUMPAD_9:
                action = Move(NorthEast);
            case Key.DOWN, Key.NUMPAD_2:
                action = Move(South);
            case Key.NUMPAD_1:
                action = Move(SouthWest);
            case Key.NUMPAD_3:
                action = Move(SouthEast);
            case Key.LEFT, Key.NUMPAD_4:
                action = Move(West);
            case Key.RIGHT, Key.NUMPAD_6:
                action = Move(East);
            case Key.SPACE, Key.NUMPAD_5:
                action = Wait;
            case Key.C:
                pushHandler(new ChooseDirectionHandler(testChooseDir));
        }
        return action;
    }

    private function testChooseDir(dir:Direction):Action
    {
        popHandler();
        if (dir == null)
        {
            trace("Direction choosing canceled");
            return null;
        }
        else
        {
            trace("Moving to chosen direction " + dir);
            return Move(dir);
        }
    }
}

typedef ChooseDirectionCallback = Direction->Action;

class ChooseDirectionHandler extends InputHandlerBase
{
    private var cb:ChooseDirectionCallback;

    public function new(cb:ChooseDirectionCallback):Void
    {
        this.cb = cb;
    }

    override public function enter():Void
    {
        trace("Choose a direction");
    }

    override public function exit():Void
    {
        trace("Direction chosen!");
    }

    override private function handleKey(key:Int):Action
    {
        if (key == Key.ESCAPE)
            return cb(null);

        var dir:Direction = switch (key)
        {
            case Key.UP, Key.NUMPAD_8:
                North;
            case Key.NUMPAD_7:
                NorthWest;
            case Key.NUMPAD_9:
                NorthEast;
            case Key.DOWN, Key.NUMPAD_2:
                South;
            case Key.NUMPAD_1:
                SouthWest;
            case Key.NUMPAD_3:
                SouthEast;
            case Key.LEFT, Key.NUMPAD_4:
                West;
            case Key.RIGHT, Key.NUMPAD_6:
                East;
            default:
                null;
        };
        if (dir != null)
            return cb(dir);
        else
            return null;
    }
}
