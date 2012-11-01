package dungeons.render;

import nme.geom.Point;
import nme.display.BitmapData;

interface IRenderer
{
    function render(target:BitmapData, position:Point):Void;
}
