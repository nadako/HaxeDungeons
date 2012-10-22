package ;

import de.polygonal.ds.Array2;
import nme.ui.Keyboard;
import components.Position;
import nodes.PlayerNode;
import net.richardlord.ash.tools.ListIteratingSystem;
import Dungeon.Tile;

class PlayerControlSystem extends ListIteratingSystem<PlayerNode>
{
    private var keyPoll:KeyPoll;
    private var dungeonGrid:Array2<Tile>;

    public function new(keyPoll:KeyPoll, dungeonGrid:Array2<Tile>)
    {
        super(PlayerNode, nodeUpdate);
        this.keyPoll = keyPoll;
        this.dungeonGrid = dungeonGrid;
    }

    private function nodeUpdate(node:PlayerNode, dt:Float):Void
    {
        if (keyPoll.isDown(Keyboard.UP))
            moveHero(node.position, 0, -1);
        else if (keyPoll.isDown(Keyboard.DOWN))
            moveHero(node.position, 0, 1);
        else if (keyPoll.isDown(Keyboard.LEFT))
            moveHero(node.position, -1, 0);
        else if (keyPoll.isDown(Keyboard.RIGHT))
            moveHero(node.position, 1, 0);
    }

    private function moveHero(position:Position, dx:Int, dy:Int):Void
    {
        var tile:Tile = dungeonGrid.get(Std.int(position.x) + dx, Std.int(position.y) + dy);
        if (tile == Floor)
        {
            position.x += dx;
            position.y += dy;
        }
    }
}
