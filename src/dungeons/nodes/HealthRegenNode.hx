package dungeons.nodes;

import ash.core.Node;

import dungeons.components.HealthRegen;
import dungeons.components.Health;

class HealthRegenNode extends Node<HealthRegenNode>
{
    public var health:Health;
    public var regen:HealthRegen;
}
