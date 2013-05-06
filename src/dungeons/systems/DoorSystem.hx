package dungeons.systems;

import com.haxepunk.Graphic;

import ash.core.Engine;
import ash.core.Entity;
import ash.tools.ListIteratingSystem;

import dungeons.components.Door;
import dungeons.components.Key;
import dungeons.components.DoorRenderable;
import dungeons.components.Renderable;
import dungeons.components.LightOccluder;
import dungeons.components.Obstacle;
import dungeons.components.Inventory;
import dungeons.nodes.DoorNode;
import dungeons.utils.MapGrid;

using dungeons.utils.EntityUtil;

class DoorSystem extends ListIteratingSystem<DoorNode>
{
    private var doorListeners:Map<DoorNode, DoorListener>;
    private var obstacle:Obstacle;
    private var lightOccluder:LightOccluder;
    private var map:MapGrid;

    public function new(map:MapGrid)
    {
        super(DoorNode, null, onNodeAdded, onNodeRemoved);
        this.map = map;
        obstacle = new Obstacle();
        lightOccluder = new LightOccluder();
    }

    override public function addToEngine(engine:Engine):Void
    {
        doorListeners = new Map<DoorNode, DoorListener>();
        super.addToEngine(engine);
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        super.removeFromEngine(engine);
        for (node in doorListeners.keys())
        {
            var listener:DoorListener = doorListeners.get(node);
            node.door.openRequested.remove(listener.openListener);
            node.door.closeRequested.remove(listener.closeListener);
        }
        doorListeners = null;
    }

    private function onNodeAdded(node:DoorNode):Void
    {
        var listener:DoorListener = {
            openListener: onNodeOpenRequested.bind(node),
            closeListener: onNodeCloseRequested.bind(node)
        };
        doorListeners.set(node, listener);
        node.door.openRequested.add(listener.openListener);
        node.door.closeRequested.add(listener.closeListener);
        updateDoor(node);
    }

    private function onNodeOpenRequested(node:DoorNode, who:Entity):Void
    {
        var door:Door = node.door;

        if (door.open)
            return;

        if (door.keyId > 0)
        {
            var inventory:Inventory = who.get(Inventory);
            if (inventory == null)
                return;

            var hasKey:Bool = false;
            for (item in inventory.items)
            {
                var key:Key = item.get(Key);
                if (key != null && key.keyId == door.keyId)
                {
                    hasKey = true;
                    break;
                }
            }

            if (!hasKey)
            {
                if (who.isPlayer())
                    MessageLogSystem.message("You don't have a key for this door (keyId="+door.keyId+")");
                return;
            }
        }

        door.open = true;
        updateDoor(node);
        MessageLogSystem.message(who.isPlayer() ? "You open the door." : "Door opens...");
    }

    private function onNodeCloseRequested(node:DoorNode, who:Entity):Void
    {
        if (node.door.open && !map.isBlocked(node.position.x, node.position.y))
        {
            node.door.open = false;
            updateDoor(node);
            MessageLogSystem.message(who.isPlayer() ? "You close the door." : "Door closes...");
        }
    }

    private function onNodeRemoved(node:DoorNode):Void
    {
        var listener:DoorListener = doorListeners.get(node);
        doorListeners.remove(node);
        node.door.openRequested.remove(listener.openListener);
        node.door.closeRequested.remove(listener.closeListener);
    }

    private function updateDoor(node:DoorNode):Void
    {
        var renderable:DoorRenderable = cast node.entity.get(Renderable);
        if (node.door.open)
        {
            node.entity.remove(Obstacle);
            node.entity.remove(LightOccluder);
            renderable.setOpen(true);
        }
        else
        {
            node.entity.add(obstacle);
            node.entity.add(lightOccluder);
            renderable.setOpen(false);
        }
    }
}

private typedef DoorListener =
{
    var openListener:OpenRequestListener;
    var closeListener:CloseRequestListener;
}
