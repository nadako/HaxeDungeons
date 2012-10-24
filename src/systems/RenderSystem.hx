package systems;

import nme.display.DisplayObjectContainer;
import nme.display.Tilesheet;

import net.richardlord.ash.core.Game;
import net.richardlord.ash.core.System;
import net.richardlord.ash.core.NodeList;

import nodes.RenderNode;

class RenderSystem extends System
{
    private var nodes:NodeList<RenderNode>;
    private var container:DisplayObjectContainer;

    public function new(container:DisplayObjectContainer)
    {
        this.container = container;
    }

    override public function addToGame(game:Game):Void
    {
        nodes = game.getNodeList(RenderNode);
        for (node in nodes)
            addToDisplay(node);
        nodes.nodeAdded.add(addToDisplay);
        nodes.nodeRemoved.add(removeFromDisplay);
    }

    override public function removeFromGame(game:Game):Void
    {
        nodes.nodeAdded.remove(addToDisplay);
        nodes.nodeRemoved.remove(removeFromDisplay);
        nodes = null;
    }

    override public function update(time:Float):Void
    {
        var TILE_SIZE:Int = 8;

        for (node in nodes)
        {
            var displayObject = node.renderable.displayObject;
            var position = node.position;

            displayObject.x = position.x * TILE_SIZE;
            displayObject.y = position.y * TILE_SIZE;
        }
    }

    private function addToDisplay(node:RenderNode):Void
    {
        container.addChild(node.renderable.displayObject);
    }

    private function removeFromDisplay(node:RenderNode):Void
    {
        container.removeChild(node.renderable.displayObject);
    }
}
