package systems;

import net.richardlord.ash.tools.ComponentPool;
import components.Move;
import de.polygonal.ds.Array2;

import net.richardlord.ash.tools.ListIteratingSystem;

import nodes.MoveNode;
import Dungeon.Tile;

class MoveSystem extends ListIteratingSystem<MoveNode>
{
    private var dungeonGrid:Array2<Tile>;

    public function new(dungeonGrid:Array2<Tile>)
    {
        super(MoveNode, updateNode);
        this.dungeonGrid = dungeonGrid;
    }

    private function updateNode(node:MoveNode, dt:Float):Void
    {
        var move:Move = node.entity.remove(Move);
        ComponentPool.dispose(Move);
        var dx:Int = 0;
        var dy:Int = 0;
        switch (move.direction)
        {
            case North:
                dy = -1;
            case South:
                dy = 1;
            case East:
                dx = 1;
            case West:
                dx = -1;
        }

        var x:Int = node.position.x + dx;
        var y:Int = node.position.y + dy;

        if (dungeonGrid.inRange(x, y) && dungeonGrid.get(x, y) == Floor)
        {
            node.position.x = x;
            node.position.y = y;
        }
    }
}
