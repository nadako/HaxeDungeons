package dungeons.nodes;

import ash.core.Node;

import dungeons.components.Fighter;
import dungeons.components.Health;
import dungeons.components.PlayerControls;

class PlayerStatsNode extends Node<PlayerStatsNode>
{
    public var player:PlayerControls;
    public var health:Health;
    public var fighter:Fighter;
}
