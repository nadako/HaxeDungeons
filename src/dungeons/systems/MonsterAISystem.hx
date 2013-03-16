package dungeons.systems;

import ash.core.Node;
import ash.core.NodeList;
import ash.core.System;
import ash.core.Engine;
import ash.ObjectMap;
import ash.tools.ListIteratingSystem;

import dungeons.components.Fighter;
import dungeons.components.Position;
import dungeons.components.PlayerControls;
import dungeons.nodes.MonsterActorNode;
import dungeons.utils.Direction;
import dungeons.utils.Vector;
import dungeons.utils.Map;

using dungeons.utils.ArrayUtil;

private class PlayerTargetNode extends Node<PlayerTargetNode>
{
    public var player:PlayerControls;
    public var position:Position;
    public var fighter:Fighter;
}

class MonsterAISystem extends ListIteratingSystem<MonsterActorNode>
{
    private var nodeListeners:ObjectMap<MonsterActorNode, Void -> Void>;
    private var playerNodeList:NodeList<PlayerTargetNode>;
    private var map:Map;

    public function new(map:Map)
    {
        this.map = map;
        super(MonsterActorNode, null, onNodeAdded, onNodeRemoved);
    }

    override public function addToEngine(engine:Engine):Void
    {
        nodeListeners = new ObjectMap();
        playerNodeList = engine.getNodeList(PlayerTargetNode);
        super.addToEngine(engine);
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        super.removeFromEngine(engine);
        for (node in nodeListeners.keys())
            node.actor.actionRequested.remove(nodeListeners.get(node));
        nodeListeners = null;
        playerNodeList = null;
    }

    private var player(get_player, never):PlayerTargetNode;

    private inline function get_player():PlayerTargetNode
    {
        return playerNodeList.head;
    }

    private function onNodeAdded(node:MonsterActorNode):Void
    {
        var listener = callback(onNodeActionRequested, node);
        node.actor.actionRequested.add(listener);
        nodeListeners.set(node, listener);
    }

    private function onNodeActionRequested(node:MonsterActorNode):Void
    {
        // if there is a player
        if (player != null)
        {
            var pos:Position = node.entity.get(Position);
            var playerPos:Position = player.position;
            var distance:Int = isVisible(pos.x, pos.y, playerPos.x, playerPos.y, node.ai.sightRadius);
            // if we can see the player
            if (distance != -1)
            {
                node.ai.setLastKnownPlayerPosition(playerPos.x, playerPos.y);

                // if we're near - attack!
                if (distance < 2)
                {
                    node.actor.setAction(Attack(player.entity));
                    return;
                }
                // else move towards him
                else
                {
                    var dir:Direction = moveTowards(pos.x, pos.y, playerPos.x, playerPos.y);
                    if (dir != null)
                    {
                        node.actor.setAction(Move(dir));
                        return;
                    }

                }
            }
            // if we have a record of last known position (TODO: implement scent-based tracking)
            else if (node.ai.lastKnownPlayerPosition != null)
            {
                // we're there, clear the position so we don't do anything next time
                var lastKnownPos:Vector = node.ai.lastKnownPlayerPosition;
                if (lastKnownPos.x == pos.x && lastKnownPos.y == pos.y)
                {
                    node.ai.clearLastKnownPlayerPosition();
                }
                else
                {
                    // try to move towards it
                    var dir:Direction = moveTowards(pos.x, pos.y, lastKnownPos.x, lastKnownPos.y);
                    if (dir != null)
                    {
                        node.actor.setAction(Move(dir));
                        return;
                    }
                    else
                    {
                        // if failed - clear the position
                        node.ai.clearLastKnownPlayerPosition();
                    }
                }
            }
        }
        node.actor.setAction(Wait);
    }

    private function moveTowards(x0:Int, y0:Int, x1:Int, y1:Int):Direction
    {
        // get -1,0,1 offset values
        var dx:Int = x1 - x0;
        var dy:Int = y1 - y0;
        var ddx:Int = 0;
        var ddy:Int = 0;
        if (dx > 0)
            ddx = 1;
        else if (dx < 0)
            ddx = -1;
        if (dy > 0)
            ddy = 1
        else if (dy < 0)
            ddy = -1;

        // target coords
        var x:Int = x0 + ddx;
        var y:Int = y0 + ddy;

        if (!map.isBlocked(x, y))
        {
            // if not blocked, return direction for this cell
            return DirectionUtil.fromOffset(ddx, ddy);
        }
        else
        {
            // else try to be "a little bit" smart (TODO: implement wall-folowing)
            if (ddx != 0)
            {
                if (!map.isBlocked(x, y0))
                    return DirectionUtil.fromOffset(ddx, 0);
            }

            if (ddy != 0)
            {
                if (!map.isBlocked(x0, y))
                    return DirectionUtil.fromOffset(0, ddy);
            }
        }

        return null;
    }

    private function directionFrom():Void
    {

    }

    private function onNodeRemoved(node:MonsterActorNode):Void
    {
        var listener = nodeListeners.get(node);
        nodeListeners.remove(node);
        node.actor.actionRequested.remove(listener);
    }

    /**
     * Standard Bresenham LoS
     **/
    private function isVisible(x0:Int, y0:Int, x1:Int, y1:Int, radius:Int):Int
    {
        var dx:Int = Std.int(Math.abs(x1 - x0));
        var dy:Int = Std.int(Math.abs(y1 - y0));
        var sx:Int = x0 < x1 ? 1 : -1;
        var sy:Int = y0 < y1 ? 1 : -1;
        var err:Int = dx - dy;

        var lineLen:Int = 0;
        while (true)
        {
            if (lineLen > radius || map.get(x0, y0).numOccluders > 0)
                return -1;

            if (x0 == x1 && y0 == y1)
                break;

            var e2:Int = err * 2;
            if (e2 > -dx)
            {
                err -= dy;
                x0 += sx;
            }
            if (e2 < dx)
            {
                err += dx;
                y0 += sy;
            }

            lineLen++;
        }

        return lineLen;
    }
}
