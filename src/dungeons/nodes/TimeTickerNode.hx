package dungeons.nodes;

import ash.core.Node;

import dungeons.components.Actor;
import dungeons.components.TimeTicker;

class TimeTickerNode extends Node<TimeTickerNode>
{
    public var ticker:TimeTicker;
    public var actor:Actor;
}
