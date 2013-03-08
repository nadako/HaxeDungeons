package dungeons.nodes;

import ash.core.Node;

import dungeons.components.Health;
import dungeons.components.Fighter;

class FighterNode extends Node<FighterNode>
{
    public var health:Health;
    public var fighter:Fighter;
}
