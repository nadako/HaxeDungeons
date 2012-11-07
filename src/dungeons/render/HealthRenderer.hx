package dungeons.render;

import nme.geom.Rectangle;
import nme.geom.Point;
import nme.display.BitmapData;

import dungeons.components.Fighter;

class HealthRenderer
{
    public var healthBarWidth(default, null):Int;
    public var healthBarHeight(default, null):Int;
    private var drawRect:Rectangle;

    public function new(healthBarWidth:Int, healthBarHeight:Int):Void
    {
        this.healthBarWidth = healthBarWidth;
        this.healthBarHeight = healthBarHeight;
        drawRect = new Rectangle(0, 0, healthBarWidth, healthBarHeight);
    }

    public function renderHealth(fighter:Fighter, target:BitmapData, x:Int, y:Int):Void
    {
        var percent:Float = fighter.currentHP / fighter.maxHP;
        var actualWidth:Int = Math.round(healthBarWidth * percent);
        drawRect.x = x;
        drawRect.y = y;
        drawRect.width = actualWidth;
        target.fillRect(drawRect, 0x99FF0000);
    }
}
