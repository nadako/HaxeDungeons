package dungeons.systems;

import ash.core.Engine;
import ash.ObjectMap;
import ash.core.Entity;
import ash.tools.ListIteratingSystem;

import dungeons.components.Position;
import dungeons.components.Inventory;
import dungeons.nodes.InventoryNode;

using dungeons.utils.EntityUtil;

class InventorySystem extends ListIteratingSystem<InventoryNode>
{
    private var pickupListeners:ObjectMap<InventoryNode, PickupListener>;
    
    public function new() 
    {
        super(InventoryNode, null, onNodeAdded, onNodeRemoved);
    }
    
    override public function addToEngine(engine:Engine):Void 
    {
        pickupListeners = new ObjectMap();
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
    
    private function onNodePickupRequested(node:InventoryNode, item:Entity):Void 
    {
        var inventory:Inventory = node.inventory;

        if (Lambda.indexOf(inventory.items, item) != -1)
            return;

        item.remove(Position);
        inventory.items.push(item);
        
        if (node.entity.isPlayer())
            MessageLogSystem.message("You picked up " + item.getName());
            
        // debug print
        var names:Array<String> = [];
        for (item in inventory.items)
            names.push(item.getName());
        trace("Current inventory: " + names.join(", "));
    }
    
    
}