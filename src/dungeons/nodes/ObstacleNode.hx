package dungeons.nodes;

import ash.core.Node;

import dungeons.components.Position;
import dungeons.components.Obstacle;

class ObstacleNode extends Node<ObstacleNode>
{
    public var obstacle:Obstacle;
    public var position:Position;
}
