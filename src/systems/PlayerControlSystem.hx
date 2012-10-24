package systems;

import flash.ui.Keyboard;
import flash.events.KeyboardEvent;
import flash.display.Sprite;

import de.polygonal.ds.Array2;

import net.richardlord.ash.core.Game;
import net.richardlord.ash.core.NodeList;
import net.richardlord.ash.core.System;

import components.Actor;
import components.Position;
import nodes.PlayerActorNode;
import Dungeon.Tile;

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
