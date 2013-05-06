package dungeons.systems;

import ash.core.Engine;
import ash.ObjectMap;
import ash.core.Entity;
import ash.tools.ListIteratingSystem;

import dungeons.components.Item;
import dungeons.components.Equipment;
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
        var listener:PickupListener = onNodePickupRequested.bind(node);
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
        var done:Bool = false;

        for (inventoryItemEntity in inventory.items)
        {
            // if it's already in inventory - wtf?
            if (inventoryItemEntity == itemEntity)
                throw "tried to pick up item that is already in inventory";

            // if it stacks, increase quantity and remove item entity from the game
            var inventoryItem:Item = inventoryItemEntity.get(Item);
            if (inventoryItem.stacksWith(item))
            {
                inventoryItem.quantity += item.quantity;
                engine.removeEntity(itemEntity);
                done = true;
                break;
            }
        }

        // if we still here, we need to add item to the inventory
        if (!done)
        {
            // remove position, so it's removed from the scene
            itemEntity.remove(Position);

            // add to inventory
            inventory.items.push(itemEntity);
        }

        var itemName:String = itemEntity.getName();

        var cnt:String = "";
        if (item.quantity > 1)
            cnt += Std.string(item.quantity) + " ";
        MessageLogSystem.message("You pickup " + cnt + itemName);

        var equipment:Equipment = itemEntity.get(Equipment);
        if (equipment != null && inventory.getEquippedInSlot(equipment.slot) == null)
        {
            inventory.equip(itemEntity);
            MessageLogSystem.message("You equip " + itemName);
        }

        inventory.updated.dispatch();
    }
}
