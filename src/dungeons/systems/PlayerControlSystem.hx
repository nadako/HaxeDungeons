package dungeons.systems;

import nme.ui.Keyboard;
import nme.events.KeyboardEvent;
import nme.display.Sprite;

import net.richardlord.ash.core.Game;
import net.richardlord.ash.core.NodeList;
import net.richardlord.ash.core.System;

import dungeons.components.Actor;
import dungeons.components.Position;
import dungeons.nodes.PlayerActorNode;
import dungeons.Dungeon.Tile;

class PlayerControlSystem extends System
{
    private var application:Sprite;
    private var nodeList:NodeList<PlayerActorNode>;

    public function new(application:Sprite)
    {
        this.application = application;
    }

    override public function addToGame(game:Game):Void
    {
        nodeList = game.getNodeList(PlayerActorNode);
        application.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    }

    override public function removeFromGame(game:Game):Void
    {
        application.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        nodeList = null;
    }

    private function onKeyDown(event:KeyboardEvent):Void
    {
        for (node in nodeList)
        {
            if (node.actor.awaitingAction)
            {
                var action = getAction(event);
                if (action != null)
                {
                    node.actor.awaitingAction = false;
                    node.actor.resultAction = action;
                }
            }
        }
    }

    private function getAction(event:KeyboardEvent):Action
    {
        switch (event.keyCode)
        {
            case Keyboard.UP:
                return Move(North);
            case Keyboard.DOWN:
                return Move(South);
            case Keyboard.LEFT:
                return Move(West);
            case Keyboard.RIGHT:
                return Move(East);
            default:
                return null;
        }
    }
}
