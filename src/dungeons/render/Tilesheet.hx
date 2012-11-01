package dungeons.render;

import nme.geom.Point;
import nme.geom.Rectangle;
import nme.display.BitmapData;

class Tilesheet
{
    private var bitmapData:BitmapData;
    private var sourceRect:Rectangle;

    public function new(bitmapData:BitmapData, tileWidth:Int, tileHeight:Int)
    {
        this.bitmapData = bitmapData;
        this.sourceRect = new Rectangle(0, 0, tileWidth, tileHeight);
    }

    public function draw(target:BitmapData, col:Int, row:Int, destPoint:Point):Void
    {
        sourceRect.x = col * sourceRect.width;
        sourceRect.y = row * sourceRect.height;
        target.copyPixels(bitmapData, sourceRect, destPoint, null, null, true);
    }
}

class TilesheetRenderer implements IRenderer
{
    private var tilesheet:Tilesheet;
    private var col:Int;
    private var row:Int;

    public function new(tilesheet:Tilesheet, col:Int, row:Int)
    {
        this.tilesheet = tilesheet;
        this.col = col;
        this.row = row;
    }

    public function render(target:BitmapData, position:Point):Void
    {
        tilesheet.draw(target, col, row, position);
    }
}
