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
import dungeons.components.Obstacle;
import dungeons.components.Item;
import dungeons.components.Position;
import dungeons.nodes.PlayerActorNode;
import dungeons.utils.Direction;
import dungeons.utils.Map;
import dungeons.utils.Vector;

using dungeons.utils.Direction.DirectionUtil;

class PlayerControlSystem extends System
{
    public var map(default, null):Map;
    private var nodeList:NodeList<PlayerActorNode>;
    private var inputHandler:IInputHandler;

    public function new(map:Map)
    {
        super();
        this.map = map;
    }

    override public function addToEngine(engine:Engine):Void
    {
        nodeList = engine.getNodeList(PlayerActorNode);
        inputHandler = new MainInputHandler(this);
        inputHandler.enter();
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        nodeList = null;
        inputHandler.exit();
        inputHandler = null;
    }

    private function getAction(entity:Entity):Action
    {
        inputHandler.bind(entity);

        var action:Action = inputHandler.processKey(Input.lastKey);

        if (action != null && Type.enumConstructor(action) == "Move")
            action = processMove(entity, action);

        inputHandler.unbind();

        return action;
    }

    private function processMove(entity:Entity, moveAction:Action):Action
    {
        var direction:Direction = Type.enumParameters(moveAction)[0];
        var position:Position = entity.get(Position);
        if (position != null)
        {
            var targetTile = position.getAdjacentTile(direction);
            var blocker:Entity = null;
            for (entity in map.get(targetTile.x, targetTile.y).entities)
            {
                if (entity.has(Obstacle))
                {
                    blocker = entity;
                    break;
                }
            }
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
    function bind(entity:Entity):Void;
    function unbind():Void;
    function processKey(key:Int):Action;
}

class InputHandlerBase implements IInputHandler
{
    private var next:IInputHandler;
    private var entity:Entity;

    public function bind(entity:Entity):Void
    {
        this.entity = entity;
        if (next != null)
            next.bind(entity);
    }

    public function unbind():Void
    {
        entity = null;
        if (next != null)
            next.unbind();
    }

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
    private var system:PlayerControlSystem;

    public function new(system:PlayerControlSystem)
    {
        this.system = system;
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
            case Key.G:
                var pos:Position = entity.get(Position);
                for (item in system.map.get(pos.x, pos.y).entities)
                {
                    if (item.has(Item))
                    {
                        action = Pickup(item);
                        break;
                    }
                }
            case Key.C:
                MessageLogSystem.message("Choose direction to close door.");
                pushHandler(new ChooseDirectionHandler(closeDoor));
        }
        return action;
    }

    private function closeDoor(dir:Direction):Action
    {
        popHandler();
        if (dir != null)
        {
            var pos:Position = entity.get(Position);
            var off:Vector = dir.offset();
            for (e in system.map.get(pos.x + off.x, pos.y + off.y).entities)
            {
                var door:Door = e.get(Door);
                if (door != null)
                    return CloseDoor(e);
            }
        }
        return null;
    }
}

typedef ChooseDirectionCallback = Direction -> Action;

class ChooseDirectionHandler extends InputHandlerBase
{
    private var cb:ChooseDirectionCallback;

    public function new(cb:ChooseDirectionCallback):Void
    {
        this.cb = cb;
    }

    override public function enter():Void
    {
    }

    override public function exit():Void
    {
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
