package dungeons.utils;

import haxe.Json;

import nme.Assets;

/**
 * Helper class for getting a wall transition tile number
 **/
class TransitionTileHelper
{
    private var transitionTiles:Map<Int, Int>;

    public function new(path:String):Void
    {
        transitionTiles = new Map<Int, Int>();
        var def:Dynamic = Json.parse(Assets.getText(path));
        for (field in Reflect.fields(def))
            transitionTiles.set(Std.parseInt(field), Reflect.field(def, field));
    }

    public function getTileNumber(transition:Int):Int
    {
        if (!transitionTiles.exists(transition))
            transition &= 15;
        return transitionTiles.get(transition);
    }
}
