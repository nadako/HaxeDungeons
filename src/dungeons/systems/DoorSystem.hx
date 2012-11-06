package dungeons.systems;

import dungeons.components.DoorRenderable;
import dungeons.components.Renderable;
import dungeons.components.LightOccluder;
import dungeons.components.Obstacle;
import nme.ObjectHash;

import net.richardlord.ash.core.Game;
import net.richardlord.ash.core.Entity;
import net.richardlord.ash.tools.ListIteratingSystem;

import dungeons.components.Door;
import dungeons.nodes.DoorNode;

class DoorSystem extends ListIteratingSystem<DoorNode>
{
    private var doorListeners:ObjectHash<DoorNode, OpenRequestListener>;
    private var obstacle:Obstacle;
    private var lightOccluder:LightOccluder;

    public function new()
    {
        super(DoorNode, null, onNodeAdded, onNodeRemoved);
        obstacle = new Obstacle();
        lightOccluder = new LightOccluder();
    }

    override public function addToGame(game:Game):Void
    {
        doorListeners = new ObjectHash();
        super.addToGame(game);
    }

    override public function removeFromGame(game:Game):Void
    {
        super.removeFromGame(game);
        for (node in doorListeners.keys())
            node.door.openRequested.remove(doorListeners.get(node));
        doorListeners = null;
    }

    private function onNodeAdded(node:DoorNode):Void
    {
        var listener = callback(onNodeOpenRequested, node);
        doorListeners.set(node, listener);
        node.door.openRequested.add(listener);
        updateDoor(node);
    }

    private function onNodeOpenRequested(node:DoorNode, who:Entity):Void
    {
        // here we can add checks for key in inventory and so on

        if (!node.door.open)
        {
            // TODO: use friend typedef cast or haxe 2.11 ACL metadata
            untyped node.door.open = true;
            updateDoor(node);
        }
    }

    private function onNodeRemoved(node:DoorNode):Void
    {
        var listener = doorListeners.get(node);
        doorListeners.remove(node);
        node.door.openRequested.remove(listener);
    }

    private function updateDoor(node:DoorNode):Void
    {
        var renderable:DoorRenderable = cast node.entity.get(Renderable);
        if (node.door.open)
        {
            node.entity.remove(Obstacle);
            node.entity.remove(LightOccluder);
            renderable.renderer = renderable.openRenderer;
        }
        else
        {
            node.entity.add(obstacle);
            node.entity.add(lightOccluder);
            renderable.renderer = renderable.closedRenderer;
        }
    }
}
