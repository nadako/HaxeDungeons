package ;

import nme.Assets;
import nme.geom.Rectangle;
import nme.geom.Matrix;
import nme.events.Event;
import nme.display.Tilesheet;
import nme.display.BitmapData;
import nme.display.StageScaleMode;
import nme.display.Sprite;
import nme.Lib;

import de.polygonal.ds.Array2;

import Dungeon.Tile;

class Main extends Sprite
{
    private var tilesheet:Tilesheet;

    private static inline var TILE_SIZE:Int = 8;

    public function new()
    {
        super();

        tilesheet = new Tilesheet(Assets.getBitmapData("oryx_lofi/lofi_environment.png"));

        // wall h
        tilesheet.addTileRect(new Rectangle(0, 2 * TILE_SIZE, TILE_SIZE, TILE_SIZE));

        // wall v
        tilesheet.addTileRect(new Rectangle(4 * TILE_SIZE, 2 * TILE_SIZE, TILE_SIZE, TILE_SIZE));

        // floor
        tilesheet.addTileRect(new Rectangle(5 * TILE_SIZE, 2 * TILE_SIZE, TILE_SIZE, TILE_SIZE));

        var dungeon = new Dungeon(new Array2Cell(50, 50), 25, new Array2Cell(5, 5), new Array2Cell(20, 20));
        dungeon.generate();

        var tileData:Array<Float> = new Array<Float>();

        for (x in 0...dungeon.grid.getW())
        {
            for (y in 0...dungeon.grid.getH())
            {
                var tileID:Float;
                switch (dungeon.grid.get(x, y))
                {
                    case Wall:
                        tileID = isVerticalWall(dungeon.grid, x, y) ? 1 : 0;
                    case Floor:
                        tileID = 2;
                    default:
                        continue;
                }
                tileData.push(x * TILE_SIZE);
                tileData.push(y * TILE_SIZE);
                tileData.push(tileID);
            }
        }

        tilesheet.drawTiles(graphics, tileData);
        scaleX = scaleY = 2;
    }

    private function isVerticalWall(grid:Array2<Tile>, x:Int, y:Int):Bool
    {
        return grid.inRange(x, y + 1) && grid.get(x, y + 1) == Wall;
    }
}
