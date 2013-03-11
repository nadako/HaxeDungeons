package dungeons.systems;

import ash.core.Engine;
import ash.ObjectMap;
import ash.core.Entity;
import ash.tools.ListIteratingSystem;

import dungeons.components.Item;
import dungeons.components.Position;
import dungeons.components.Inventory;
import dungeons.nodes.InventoryNode;

using dungeons.utils.EntityUtil;

class InventorySystem extends ListIteratingSystem<InventoryNode>
{
    private var pickupListeners:ObjectMap<InventoryNode, PickupListener>;
    private var engine:Engine;

    public function new()
    {
        super(InventoryNode, null, onNodeAdded, onNodeRemoved);
    }

    override public function addToEngine(engine:Engine):Void
    {
        pickupListeners = new ObjectMap();
        this.engine = engine;
        super.addToEngine(engine);
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        super.removeFromEngine(engine);
        for (node in pickupListeners.keys())
        {
            var listener:PickupListener = pickupListeners.get(node);
            node.inventory.pickupRequested.remove(listener);
            pickupListeners.remove(node);
        }
        pickupListeners = null;
        this.engine = null;
    }

    private function onNodeAdded(node:InventoryNode):Void
    {
        var listener:PickupListener = callback(onNodePickupRequested, node);
        node.inventory.pickupRequested.add(listener);
        pickupListeners.set(node, listener);
    }

    private function onNodeRemoved(node:InventoryNode):Void
    {
        var listener:PickupListener = pickupListeners.get(node);
        pickupListeners.remove(node);
        node.inventory.pickupRequested.remove(listener);
    }

    private function onNodePickupRequested(node:InventoryNode, itemEntity:Entity):Void
    {
        var inventory:Inventory = node.inventory;
        var item:Item = itemEntity.get(Item);

        for (inventoryItemEntity in inventory.items)
        {
            // if it's already in inventory - wtf?
            if (inventoryItemEntity == itemEntity)
                throw "tried to pick up item that is already in inventory";

            // if it stacks, increase quantity and remove item entity from the world
            var inventoryItem:Item = inventoryItemEntity.get(Item);
            if (inventoryItem.stacksWith(item))
            {
                inventoryItem.quantity += item.quantity;
                engine.removeEntity(itemEntity);
                return;
            }
        }

        // if we still here, we need to add item to the inventory

        // remove position, so it's removed from the spatial world
        itemEntity.remove(Position);

        // add to inventory
        inventory.items.push(itemEntity);
    }
}