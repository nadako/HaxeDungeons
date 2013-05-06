package dungeons;

import com.haxepunk.graphics.Spritemap;
import com.haxepunk.Graphic;
import haxe.Json;

import nme.geom.Rectangle;
import nme.geom.Matrix;
import nme.display.BitmapData;
import nme.Assets;

import com.haxepunk.HXP;
import com.haxepunk.graphics.Image;

class AssetFactory
{
    public var tileSize(default, null):Int;

    private var def:TilesetDef;
    private var images:Map<String, BitmapData>;
    private var tileRect:Rectangle;
    private var scaleMatrix:Matrix;

    public function new(tileset:String)
    {
        def = Json.parse(Assets.getText(tileset));
        images = new Map<String, BitmapData>();
        tileSize = def.tileSize * def.scale;
        tileRect = new Rectangle(0, 0, tileSize, tileSize);
        scaleMatrix = new Matrix();
        scaleMatrix.scale(def.scale, def.scale);
    }

    public function createTileImage(name:String):Graphic
    {
        var key:String = Reflect.field(def.tiles, name);

        var parts = key.split(":");
        var assetPath;
        var frames = [];
        try
        {
            assetPath = parts.shift();
            for (frameData in parts)
            {
                var frameParts = frameData.split(",");
                var col:Int = Std.parseInt(frameParts[0]);
                var row:Int = Std.parseInt(frameParts[1]);
                frames.push({col: col, row: row});
            }
        }
        catch (e:Dynamic)
        {
            throw "Malformed tile key: " + key;
        }

        var bmp:BitmapData = getImage(assetPath);

        if (frames.length > 1)
        {
            var spritemap:Spritemap = new Spritemap(bmp, tileSize, tileSize);
            var cols:Int = Std.int(bmp.width / tileSize);
            var animFrames = [for (frame in frames) frame.row * cols + frame.col];
            spritemap.add("", animFrames, 1);
            spritemap.play();
            return spritemap;
        }
        else
        {
            tileRect.x = frames[0].col * tileSize;
            tileRect.y = frames[0].row * tileSize;
            return new Image(bmp, tileRect.clone());
        }
    }

    public function getImage(path:String):BitmapData
    {
        var result:BitmapData = images.get(path);
        if (result == null)
        {
            var orig:BitmapData = Assets.getBitmapData(path);
            result = new BitmapData(orig.width * def.scale, orig.height * def.scale, true, 0);
            result.draw(orig, scaleMatrix, null, null, null, false);
            images.set(path, result);
        }
        return result;
    }
}

private typedef TilesetDef =
{
    var tileSize:Int;
    var scale:Int;
    var tiles:Dynamic;
}
