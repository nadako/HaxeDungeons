package dungeons.render;

import nme.geom.Matrix;
import nme.display.BitmapData;
import nme.geom.Point;
import nme.display.Shape;

class ShapeRenderer implements IRenderer
{
    private var shape:Shape;
    private static var matrix:Matrix;

    public function new(shape:Shape)
    {
        this.shape = shape;
        if (matrix == null)
            matrix = new Matrix();
    }

    public function render(target:BitmapData, position:Point):Void
    {
        matrix.identity();
        matrix.translate(position.x, position.y);
        target.draw(shape, matrix);
    }
}
