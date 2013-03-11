package dungeons.nodes;

import ash.core.Node;

import dungeons.components.Inventory;
import dungeons.components.PlayerControls;

class PlayerInventoryNode extends Node<PlayerInventoryNode>
{
    public var player:PlayerControls;
    public var inventory:Inventory;
}
