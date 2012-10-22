package ;

import components.TileRenderable;
import net.richardlord.ash.core.Entity;
import components.Position;
import nme.events.KeyboardEvent;
import nme.ui.Keyboard;
import nme.display.Shape;
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
import net.richardlord.ash.core.Game;

import Dungeon;
import ShadowCaster;

using ArrayUtil;

class Main extends Sprite, implements IShadowCasterDataProvider
{
    private static inline var TILE_SIZE:Int = 8;
    private static inline var HERO_SIGHT_RADIUS:Int = 10;

    private var dungeonTilesheet:Tilesheet;
    private var characterTilesheet:Tilesheet;

    private var dungeon:Dungeon;

    private var scene:Sprite;
    private var dungeonCanvas:Shape;
    private var lightCanvas:Shape;
    private var objectsCanvas:Shape;

    private var hero:Array2Cell;
    private var lightCaster:ShadowCaster;

    public function new()
    {
        super();
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(event:Event):Void
    {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

        scene = new Sprite();
        scene.scaleX = scene.scaleY = 2;
        addChild(scene);

        dungeonTilesheet = new Tilesheet(Assets.getBitmapData("oryx_lofi/lofi_environment.png"));
        dungeonTilesheet.addTileRect(new Rectangle(0, 2 * TILE_SIZE, TILE_SIZE, TILE_SIZE)); // wall h
        dungeonTilesheet.addTileRect(new Rectangle(4 * TILE_SIZE, 2 * TILE_SIZE, TILE_SIZE, TILE_SIZE)); // wall v
        dungeonTilesheet.addTileRect(new Rectangle(5 * TILE_SIZE, 2 * TILE_SIZE, TILE_SIZE, TILE_SIZE)); // floor

        characterTilesheet = new Tilesheet(Assets.getBitmapData("oryx_lofi/lofi_char.png"));
        characterTilesheet.addTileRect(new Rectangle(0, 0, TILE_SIZE, TILE_SIZE)); // sample char

        dungeonCanvas = new Shape();
        scene.addChild(dungeonCanvas);

        var game:Game = new Game();

        lightCanvas = new Shape();
        scene.addChild(lightCanvas);

        objectsCanvas = new Shape();
        scene.addChild(objectsCanvas);

        dungeon = new Dungeon(new Array2Cell(50, 50), 25, new Array2Cell(5, 5), new Array2Cell(20, 20));
        dungeon.generate();
        for (y in 0...dungeon.grid.getH())
        {
            for (x in 0...dungeon.grid.getW())
            {
                var entity:Entity = new Entity();
                entity.add(new Position(x, y));
                entity.add(new TileRenderable(dungeon.grid.get(x, y)));
                game.addEntity(entity);
            }
        }

        game.addSystem(new DungeonRenderSystem(dungeonCanvas.graphics, dungeonTilesheet), 0);
        game.update(0);

        lightCaster = new ShadowCaster(this);

        var startRoom:Room = dungeon.rooms.randomChoice();
        hero = new Array2Cell(startRoom.position.x + Std.int(startRoom.grid.getW() / 2), startRoom.position.y + Std.int(startRoom.grid.getH() / 2));

        redrawObjects();
        redrawLight();

        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    }

    private function onKeyDown(event:KeyboardEvent):Void
    {
        switch (event.keyCode)
        {
            case Keyboard.UP:
                moveHero(0, -1);
            case Keyboard.DOWN:
                moveHero(0, 1);
            case Keyboard.LEFT:
                moveHero(-1, 0);
            case Keyboard.RIGHT:
                moveHero(1, 0);
        }
    }

    private function moveHero(dx:Int, dy:Int):Void
    {
        var tile:Tile = dungeon.grid.get(hero.x + dx, hero.y + dy);
        if (tile == Floor)
        {
            hero.x += dx;
            hero.y += dy;
            redrawObjects();
            redrawLight();
        }
    }

    private function redrawLight():Void
    {
        lightCanvas.graphics.clear();
        lightCaster.calculateLight(hero.x, hero.y, HERO_SIGHT_RADIUS);
    }

    private function redrawObjects():Void
    {
        objectsCanvas.graphics.clear();
        characterTilesheet.drawTiles(objectsCanvas.graphics, [hero.x * TILE_SIZE, hero.y * TILE_SIZE, 0]);
        scene.x = stage.stageWidth / 2 - hero.x * TILE_SIZE * scene.scaleX;
        scene.y = stage.stageHeight / 2 - hero.y * TILE_SIZE * scene.scaleY;
    }

    private function isVerticalWall(grid:Array2<Tile>, x:Int, y:Int):Bool
    {
        return grid.inRange(x, y + 1) && grid.get(x, y + 1) == Wall;
    }

    public function isBlocking(x:Int, y:Int):Bool
    {
        var tile:Tile = dungeon.grid.get(x, y);
        return tile == Wall || tile == Empty;
    }

    public function light(x:Int, y:Int, intensity:Float):Void
    {
        lightCanvas.graphics.beginFill(0xFFFF00, 0.5);
        lightCanvas.graphics.drawRect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE);
        lightCanvas.graphics.endFill();
    }
}
