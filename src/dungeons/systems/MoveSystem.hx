package dungeons.systems;

import net.richardlord.ash.core.Game;
import net.richardlord.ash.tools.ComponentPool;
import net.richardlord.ash.tools.ListIteratingSystem;

import dungeons.components.Position;
import dungeons.components.Move;
import dungeons.nodes.MoveNode;

class MoveSystem extends ListIteratingSystem<MoveNode>
{
    private var obstacleSystem:ObstacleSystem;

    public function new()
    {
        super(MoveNode, null, nodeAdded);
    }

    override public function addToGame(game:Game):Void
    {
        obstacleSystem = game.getSystem(ObstacleSystem);
        super.addToGame(game);
    }

    override public function removeFromGame(game:Game):Void
    {
        super.removeFromGame(game);
        obstacleSystem = null;
    }

    private function nodeAdded(node:MoveNode):Void
    {
        var position:Position = node.position;

        var x:Int = position.x;
        var y:Int = position.y;

        switch (node.move.direction)
        {
            case North:
                y--;
            case South:
                y++;
            case East:
                x++;
            case West:
                x--;
        }

        if (!obstacleSystem.isBlocked(x, y))
            node.position.moveTo(x, y);

        ComponentPool.dispose(node.entity.remove(Move));
    }
}
