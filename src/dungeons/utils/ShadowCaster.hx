package dungeons.utils;

/**
 * Recursive shadow casting algorithm implementation.
 *
 * See http://roguebasin.roguelikedevelopment.org/index.php?title=FOV_using_recursive_shadowcasting
 **/
class ShadowCaster implements IIntensityCalculator
{
    private static var coordMultipliers:Array<Array<Int>>;

    private var provider:IShadowCasterDataProvider;
    private var intensityCalculator:IIntensityCalculator;

    public function new(provider:IShadowCasterDataProvider, intensityCalculator:IIntensityCalculator = null)
    {
        // coordinate multipliers for different octants
        if (coordMultipliers == null)
            coordMultipliers = [
                [1,  0,  0, -1, -1,  0,  0,  1],
                [0,  1, -1,  0,  0, -1,  1,  0],
                [0,  1,  1,  0,  0, -1, -1,  0],
                [1,  0,  0,  1, -1,  0,  0, -1]
            ];

        this.provider = provider;
        this.intensityCalculator = (intensityCalculator != null) ? intensityCalculator : this;
    }

    public function calculateLight(x:Int, y:Int, radius:Int):Void
    {
        provider.light(x, y, 1);

        // call recursive checking for each octant
        for (octant in 0...8)
            castLight(x, y, 1, 1.0, 0.0, radius, radius * radius, coordMultipliers[0][octant], coordMultipliers[1][octant], coordMultipliers[2][octant], coordMultipliers[3][octant]);
    }

    private function castLight(cx:Int, cy:Int, row:Int, startSlope:Float, endSlope:Float, radius:Int, radiusSquared:Int, xx:Int, xy:Int, yx:Int, yy:Int):Void
    {
        if (startSlope < endSlope)
            return;

        var newStartSlope:Float = 0.0;

        // for each row in radius...
        for (j in row...radius + 1)
        {
            // starting scan coords
            var dx:Int = -j - 1; // -1 here, because we increase dx before doing anything else
            var dy:Int = -j;

            // blocked flag (setting to true when got blocking cell)
            var blocked:Bool = false;

            while (dx <= 0)
            {
                dx++;

                var lSlope:Float = (dx - 0.5) / (dy + 0.5); // slope to bottom-right of the cell
                var rSlope:Float = (dx + 0.5) / (dy - 0.5); // slope to top-left of the cell

                //  we're not interested in cells on the other sides of slope
                if (startSlope < rSlope)
                    continue;
                else if (endSlope > lSlope)
                    break;

                // translate the dx, dy coordinates into map coordinates
                var mapX:Int = cx + dx * xx + dy * xy;
                var mapY:Int = cy + dx * yx + dy * yy;

                // calculate squared distance from light position
                var distSquared = dx * dx + dy * dy;

                // our light beam is touching this square, so light it
                if (distSquared < radiusSquared)
                {
                    var intensity = intensityCalculator.calculateIntensity(distSquared, radiusSquared);
                    provider.light(mapX, mapY, intensity);
                }

                // if previous cell was blocking, we're scanning a section of blocking cells
                if (blocked)
                {
                    // if it's still blocking, store the new slope and skip cycle
                    if (provider.isBlocking(mapX, mapY))
                    {
                        newStartSlope = rSlope;
                        continue;
                    }
                    // if it's not blocking, set the start slope to last blocking one
                    else
                    {
                        blocked = false;
                        startSlope = newStartSlope;
                    }
                }
                // if previous cell was not blocking, check current
                else
                {
                    if (j < radius && provider.isBlocking(mapX, mapY))
                    {
                        // this is a blocking square, start a child scan
                        blocked = true;
                        castLight(cx, cy, j + 1, startSlope, lSlope, radius, radiusSquared, xx, xy, yx, yy);
                        newStartSlope = rSlope;
                    }
                }
            }

            // if final cell was blocking, we don't need to scan next row,
            // because we created recursive scanners for further work
            if (blocked)
                break;
        }
    }

    public function calculateIntensity(distSquared:Int, radiusSquared:Int):Float
    {
        return 1.0 - distSquared / radiusSquared;
    }
}

interface IShadowCasterDataProvider
{
    function isBlocking(x:Int, y:Int):Bool;
    function light(x:Int, y:Int, intensity:Float):Void;
}

interface IIntensityCalculator
{
    function calculateIntensity(distSquared:Int, radiusSquared:Int):Float;
}