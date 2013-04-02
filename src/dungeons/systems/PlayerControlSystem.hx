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
    private var inputStates:List<IInputState>;

    public function new(map:Map)
    {
        super();
        this.map = map;
    }

    override public function addToEngine(engine:Engine):Void
    {
        nodeList = engine.getNodeList(PlayerActorNode);
        inputStates = new List();
        pushState(new MainInputState());
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        nodeList = null;
        inputStates = null;
    }

    public function pushState(state:IInputState):Void
    {
        var from:IInputState = inputStates.first();
        inputStates.push(state);
        state.enter(this, from);
    }

    public function popState():Void
    {
        var state:IInputState = inputStates.pop();
        if (state == null)
            throw "no input state to pop";
        state.exit(this, inputStates.first());
    }

    private function getAction(entity:Entity):Action
    {
        var state:IInputState = inputStates.first();
        var action:Action = state.getAction(this, entity);
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

interface IInputState
{
    function enter(system:PlayerControlSystem, from:IInputState):Void;
    function exit(system:PlayerControlSystem, to:IInputState):Void;
    function getAction(system:PlayerControlSystem, entity:Entity):Action;
}

class BaseInputState implements IInputState
{
    public function new()
    {
    }

    public function enter(system:PlayerControlSystem, from:IInputState):Void
    {
    }

    public function exit(system:PlayerControlSystem, to:IInputState):Void
    {
    }

    public function getAction(system:PlayerControlSystem, entity:Entity):Action
    {
        return null;
    }
}

class KeyUtil
{
    public static function keyToDirection(key:Int):Direction
    {
        return switch (key)
        {
            case Key.HOME, Key.NUMPAD_7:
                NorthWest;
            case Key.UP, Key.NUMPAD_8:
                North;
            case Key.PAGE_UP, Key.NUMPAD_9:
                NorthEast;
            case Key.LEFT, Key.NUMPAD_4:
                West;
            case Key.RIGHT, Key.NUMPAD_6:
                East;
            case Key.END, Key.NUMPAD_1:
                SouthWest;
            case Key.DOWN, Key.NUMPAD_2:
                South;
            case Key.PAGE_DOWN, Key.NUMPAD_3:
                SouthEast;
            default:
                null;
        };
    }
}

class MainInputState extends BaseInputState
{
    override public function getAction(system:PlayerControlSystem, entity:Entity):Action
    {
        if (!Input.pressed(Key.ANY))
            return null;

        var action:Action = null;
        var key:Int = Input.lastKey;
        var moveDir:Direction = KeyUtil.keyToDirection(key);
        if (moveDir != null)
        {
            action = Move(moveDir);
        }
        else
        {
            switch (key)
            {
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
                    system.pushState(new ChooseDirectionState(closeDoor));
            }
        }
        return action;
    }

    private function closeDoor(system:PlayerControlSystem, entity:Entity, dir:Direction):Action
    {
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

typedef ChooseDirectionCallback = PlayerControlSystem -> Entity -> Direction -> Action;

class ChooseDirectionState extends BaseInputState
{
    private var cb:ChooseDirectionCallback;

    public function new(cb:ChooseDirectionCallback):Void
    {
        super();
        this.cb = cb;
    }

    override public function getAction(system:PlayerControlSystem, entity:Entity):Action
    {
        if (!Input.pressed(Key.ANY))
            return null;

        var key:Int = Input.lastKey;

        if (key == Key.ESCAPE)
        {
            system.popState();
            return cb(system, entity, null);
        }

        var dir:Direction = KeyUtil.keyToDirection(key);
        if (dir != null)
        {
            system.popState();
            return cb(system, entity, dir);
        }
        else
            return null;
    }
}
