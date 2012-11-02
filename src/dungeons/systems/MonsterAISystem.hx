package dungeons.systems;

import dungeons.Dungeon;
import dungeons.nodes.MonsterActorNode;

import net.richardlord.ash.tools.ListIteratingSystem;
import net.richardlord.ash.core.System;
import net.richardlord.ash.core.Game;

using dungeons.ArrayUtil;

class MonsterAISystem extends ListIteratingSystem<MonsterActorNode>
{
    private static inline var directions:Array<Direction> = [North, South, West, East];

    public function new()
    {
        super(MonsterActorNode, updateNode);
    }

    private function updateNode(node:MonsterActorNode, dt:Float):Void
    {
        if (node.actor.awaitingAction)
        {
            node.actor.awaitingAction = false;
            node.actor.resultAction = Move(directions.randomChoice());
        }
    }
}
