package dungeons.systems;

import nme.ui.Keyboard;
import nme.events.KeyboardEvent;
import nme.display.Sprite;

import net.richardlord.ash.core.Entity;
import net.richardlord.ash.core.Game;
import net.richardlord.ash.core.NodeList;
import net.richardlord.ash.core.System;

import dungeons.components.Actor;
import dungeons.components.Door;
import dungeons.components.Position;
import dungeons.nodes.PlayerActorNode;
import dungeons.Dungeon;

class PlayerControlSystem extends System
{
    private var application:Sprite;
    private var obstacleSystem:ObstacleSystem;
    private var nodeList:NodeList<PlayerActorNode>;

    public function new(application:Sprite)
    {
        this.application = application;
    }

    override public function addToGame(game:Game):Void
    {
        nodeList = game.getNodeList(PlayerActorNode);
        obstacleSystem = game.getSystem(ObstacleSystem);
        application.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    }

    override public function removeFromGame(game:Game):Void
    {
        application.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        obstacleSystem = null;
        nodeList = null;
    }

    private function onKeyDown(event:KeyboardEvent):Void
    {
        for (node in nodeList)
        {
            if (node.actor.awaitingAction)
            {
                var action = getAction(node.entity, event);
                if (action != null)
                    node.actor.setAction(action);
            }
        }
    }

    private function getAction(entity:Entity, event:KeyboardEvent):Action
    {
        var action:Action;
        switch (event.keyCode)
        {

            case Keyboard.UP:
                action = Move(North);
            case Keyboard.DOWN:
                action = Move(South);
            case Keyboard.LEFT:
                action = Move(West);
            case Keyboard.RIGHT:
                action = Move(East);
            case Keyboard.SPACE:
                action = Wait;
            default:
                action = null;
        }

        if (Type.enumConstructor(action) == "Move")
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
}
