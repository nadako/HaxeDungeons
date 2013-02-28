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
import dungeons.Dungeon;

class PlayerControlSystem extends System
{
    private var obstacleSystem:ObstacleSystem;
    private var nodeList:NodeList<PlayerActorNode>;

    public function new()
    {
        super();
    }

    override public function addToEngine(engine:Engine):Void
    {
        nodeList = engine.getNodeList(PlayerActorNode);
        obstacleSystem = engine.getSystem(ObstacleSystem);
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        obstacleSystem = null;
        nodeList = null;
    }

    private function getAction(entity:Entity):Action
    {
        var action:Action = switch (Input.lastKey)
        {

            case Key.UP:
                Move(North);
            case Key.DOWN:
                Move(South);
            case Key.LEFT:
                Move(West);
            case Key.RIGHT:
                Move(East);
            case Key.SPACE:
                Wait;
            default:
                null;
        }

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
