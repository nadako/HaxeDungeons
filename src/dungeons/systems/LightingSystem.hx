package dungeons.systems;

import nme.display.Graphics;

import de.polygonal.ds.Array2;
import net.richardlord.ash.tools.ListIteratingSystem;

import dungeons.Dungeon.Tile;
import dungeons.ShadowCaster.IShadowCasterDataProvider;
import dungeons.nodes.LightSourceNode;

class LightingSystem extends ListIteratingSystem<LightSourceNode>, implements IShadowCasterDataProvider
{
    private var lightCaster:ShadowCaster;
    private var dungeonGrid:Array2<Tile>;
    private var canvas:Graphics;

    public function new(canvas:Graphics, dungeonGrid:Array2<Tile>)
    {
        this.canvas = canvas;
        this.dungeonGrid = dungeonGrid;
        lightCaster = new ShadowCaster(this);
        super(LightSourceNode, nodeUpdate);
    }

    private function nodeUpdate(node:LightSourceNode, dt:Float):Void
    {
        canvas.clear();
        lightCaster.calculateLight(Std.int(node.position.x), Std.int(node.position.y), node.lightSource.radius);
    }

    public function isBlocking(x:Int, y:Int):Bool
    {
        var tile:Tile = dungeonGrid.get(x, y);
        return tile == Wall || tile == Empty;
    }

    public function light(x:Int, y:Int, intensity:Float):Void
    {
        canvas.beginFill(0xFFFF00, intensity);
        canvas.drawRect(x * Constants.TILE_SIZE, y * Constants.TILE_SIZE, Constants.TILE_SIZE, Constants.TILE_SIZE);
        canvas.endFill();
    }
}
