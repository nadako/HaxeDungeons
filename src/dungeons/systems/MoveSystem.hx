package dungeons.systems;

import net.richardlord.ash.core.Game;
import net.richardlord.ash.tools.ComponentPool;
import net.richardlord.ash.tools.ListIteratingSystem;

import dungeons.components.Move;
import dungeons.nodes.MoveNode;

class MoveSystem extends ListIteratingSystem<MoveNode>
{
    private var obstacleSystem:ObstacleSystem;

    public function new()
    {
        super(MoveNode, updateNode);
    }

    override public function addToGame(game:Game):Void
    {
        super.addToGame(game);
        obstacleSystem = game.getSystem(ObstacleSystem);
    }

    private function updateNode(node:MoveNode, dt:Float):Void
    {
        var dx:Int = 0;
        var dy:Int = 0;
        switch (node.move.direction)
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

        ComponentPool.dispose(node.entity.remove(Move));

        var x:Int = node.position.x + dx;
        var y:Int = node.position.y + dy;

        if (!obstacleSystem.isBlocked(x, y))
            node.position.moveBy(dx, dy);
    }
}
