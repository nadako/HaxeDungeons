package dungeons;

import com.haxepunk.graphics.Image;
import com.haxepunk.graphics.Graphiclist;
import com.haxepunk.graphics.Spritemap;
import com.haxepunk.graphics.Tilemap;
import com.haxepunk.Graphic;
import com.haxepunk.HXP;
import com.haxepunk.Scene;

import haxe.Json;

import nme.display.Bitmap;
import nme.display.DisplayObjectContainer;
import nme.events.KeyboardEvent;
import nme.ui.Keyboard;
import nme.display.Shape;
import nme.Assets;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.geom.Matrix;
import nme.events.Event;
import nme.display.BitmapData;
import nme.display.StageScaleMode;
import nme.display.Sprite;
import nme.text.TextFormat;
import nme.text.TextField;
import nme.Lib;

import ash.core.Engine;
import ash.core.Entity;

import dungeons.components.Health;
import dungeons.components.Description;
import dungeons.components.MonsterAI;
import dungeons.components.Obstacle;
import dungeons.components.FOV;
import dungeons.components.CameraFocus;
import dungeons.components.Actor;
import dungeons.components.PlayerControls;
import dungeons.components.Position;
import dungeons.components.LightOccluder;
import dungeons.components.DoorRenderable;
import dungeons.components.Door;
import dungeons.components.Fighter;
import dungeons.components.Renderable;
import dungeons.components.Item;
import dungeons.components.Inventory;

import dungeons.systems.MessageLogSystem;
import dungeons.systems.FightSystem;
import dungeons.systems.MonsterAISystem;
import dungeons.systems.SystemPriorities;
import dungeons.systems.PositionSystem;
import dungeons.systems.ActorSystem;
import dungeons.systems.CameraSystem;
import dungeons.systems.FOVSystem;
import dungeons.systems.PlayerControlSystem;
import dungeons.systems.RenderSystem;
import dungeons.systems.ObstacleSystem;
import dungeons.systems.DoorSystem;
import dungeons.systems.InventorySystem;

import dungeons.mapgen.Dungeon;
import dungeons.utils.ShadowCaster;
import dungeons.utils.TransitionTileHelper;
import dungeons.utils.Map;
import dungeons.utils.Vector;

using dungeons.utils.ArrayUtil;

class GameScene extends Scene
{
    private var engine:Engine;
    private var renderSystem:RenderSystem;

    public function new()
    {
        super();
    }

    override public function begin()
    {
        engine = new Engine();

        var dungeon:Dungeon = new Dungeon(50, 50, 25, {x: 5, y: 5}, {x: 15, y: 15});
        dungeon.generate();

        var map:Map = new Map(dungeon.width, dungeon.height);

        var levelBmp:BitmapData = getScaledBitmapData("eight2empire/level assets.png");
        var itemBmp:BitmapData = getScaledBitmapData("eight2empire/item assets.png");
        var charBmp:BitmapData = getScaledBitmapData("oryx_lofi/lofi_char.png");
        var transitionHelper:TransitionTileHelper = new TransitionTileHelper("eight2empire_transitions.json");

        var levelGraphic:Graphic = renderDungeon(dungeon, levelBmp, transitionHelper);
        var level:Entity = new Entity();
        level.add(new Renderable(levelGraphic, RenderLayers.DUNGEON));
        level.add(new Position());
        engine.addEntity(level);

        // marker components can easily be a reusable single instance
        var lightOccluder:LightOccluder = new LightOccluder();
        var obstacle:Obstacle = new Obstacle();

        var startRoom:Room = dungeon.rooms.randomChoice();

        for (y in 0...dungeon.height)
        {
            for (x in 0...dungeon.width)
            {
                switch (dungeon.grid.get(x, y))
                {
                    case Wall:
                        var entity:Entity = new Entity();
                        entity.add(new Position(x, y));
                        entity.add(obstacle);
                        entity.add(lightOccluder);
                        engine.addEntity(entity);
                    case Door(open):
                        var door:Entity = new Entity();
                        door.add(new Position(x, y));
                        door.add(new dungeons.components.Door(open));
                        var col:Int = Std.random(11);
                        door.add(new DoorRenderable(createTileImage(levelBmp, col, 31), createTileImage(levelBmp, col, 30)), Renderable);
                        engine.addEntity(door);
                    default:
                        continue;
                }
            }
        }

        var startPoint:Vector = getRandomRoomPoint(startRoom);

        var hero:Entity = new Entity();
        hero.name = "player";
        hero.add(new Renderable(createTileImage(charBmp, 1, 0), RenderLayers.CHARACTER));
        hero.add(new PlayerControls());
        hero.add(new Actor(150));
        hero.add(new Position(startPoint.x, startPoint.y));
        hero.add(new CameraFocus());
        hero.add(new FOV(10));
        hero.add(new Health(10));
        hero.add(new Fighter(3, 1));
        hero.add(new Inventory());
        hero.add(obstacle);
        engine.addEntity(hero);

        var upStairs:Entity = new Entity();
        upStairs.add(new Position(startPoint.x, startPoint.y));
        upStairs.add(new Renderable(createTileImage(levelBmp, 21, 2), RenderLayers.OBJECT));
        engine.addEntity(upStairs);

        var monsterDefs:Array<MonsterDefinition> = cast Json.parse(Assets.getText("monsters.json"));
        var weaponDefs:Array<WeaponDefinition> = cast Json.parse(Assets.getText("weapons.json"));
        for (room in dungeon.rooms)
        {
            var randomPoint:Vector;

            if (room != startRoom)
            {
                randomPoint = getRandomRoomPoint(room);
                var monsterDef:MonsterDefinition = monsterDefs.randomChoice();
                var monster:Entity = new Entity();
                monster.add(new Description(monsterDef.name));
                monster.add(new Renderable(createTileImage(charBmp, monsterDef.tileCol, monsterDef.tileRow), RenderLayers.CHARACTER));
                monster.add(new Position(randomPoint.x, randomPoint.y));
                monster.add(new Actor(100));
                monster.add(new Health(monsterDef.hp));
                monster.add(new Fighter(monsterDef.power, monsterDef.defense));
                monster.add(obstacle);
                monster.add(new MonsterAI());
                engine.addEntity(monster);
            }

            var goldDesc:Description = new Description("Gold");
            if (Math.random() < 0.3)
            {
                randomPoint = getRandomRoomPoint(room);
                var gold:Entity = new Entity();
                var quantity:Int = 1 + Std.random(30);
                gold.add(new Item("gold", true, quantity));
                gold.add(new Position(randomPoint.x, randomPoint.y));
                gold.add(new Renderable(createTileImage(itemBmp, Std.random(15), 8)));
                gold.add(goldDesc);
                engine.addEntity(gold);
            }

            if (Math.random() < 0.3)
            {
                randomPoint = getRandomRoomPoint(room);
                var weaponDef:WeaponDefinition = weaponDefs.randomChoice();
                var weapon:Entity = new Entity();
                weapon.add(new Item(weaponDef.name, false, 1));
                weapon.add(new Position(randomPoint.x, randomPoint.y));
                weapon.add(new Renderable(createTileImage(itemBmp, weaponDef.tileCol, weaponDef.tileRow)));
                weapon.add(new Description(weaponDef.name));
                engine.addEntity(weapon);
            }

            if (Math.random() < 0.3)
            {
                randomPoint = getRandomRoomPoint(room);
                var blood:Entity = new Entity();
                blood.add(new Position(randomPoint.x, randomPoint.y));
                blood.add(new Renderable(createTileImage(levelBmp, Std.random(15), 37)));
                engine.addEntity(blood);
            }

            var decor:RoomDecor = RoomDecor.randomChoice();
            switch (decor)
            {
                case Library:
                    var y:Int = room.y + 1;
                    for (x in room.x + 1...room.x + room.grid.width - 1)
                    {
                        if (Math.random() < 0.1)
                            continue;

                        if (x == room.x + 1 && dungeon.grid.get(x - 1, y) != Tile.Wall)
                            continue;

                        if (x == room.x + room.grid.width - 2 && dungeon.grid.get(x + 1, y) != Tile.Wall)
                            continue;

                        if (dungeon.grid.get(x, y - 1) != Tile.Wall)
                            continue;

                        var shelf:Entity = new Entity();
                        shelf.add(new Position(x, y));
                        shelf.add(obstacle);
                        shelf.add(new Renderable(createTileImage(levelBmp, 14 + Std.random(6), 22), RenderLayers.OBJECT));
                        engine.addEntity(shelf);
                    }
                case Fountain:
                    var fountain:Entity = new Entity();
                    fountain.add(new Position(room.x + Std.int(room.grid.width / 2), Std.int(room.y + room.grid.height / 2)));
                    fountain.add(obstacle);
                    fountain.add(new Renderable(createAnimation(levelBmp, [[15, 28], [16, 28]], RenderLayers.OBJECT)));
                    engine.addEntity(fountain);
                case Light:
                    var light:Entity = new Entity();
                    light.add(new Position(room.x + Std.int(room.grid.width / 2), Std.int(room.y + room.grid.height / 2)));
                    light.add(obstacle);
                    light.add(new Renderable(createAnimation(levelBmp, [[17, 28], [18, 28]], RenderLayers.OBJECT)));
                    engine.addEntity(light);
                default:
            }
        }

        // These systems don't do anything on ticks, instead they react on signals
        engine.addSystem(new MonsterAISystem(map), SystemPriorities.NONE);
        engine.addSystem(new ObstacleSystem(map), SystemPriorities.NONE);
        engine.addSystem(new FOVSystem(map), SystemPriorities.NONE);
        engine.addSystem(new PositionSystem(map), SystemPriorities.NONE);
        engine.addSystem(new CameraSystem(), SystemPriorities.NONE);
        engine.addSystem(new DoorSystem(), SystemPriorities.NONE);
        engine.addSystem(new FightSystem(), SystemPriorities.NONE);
        engine.addSystem(new InventorySystem(), SystemPriorities.NONE);

        // Input system runs first
        engine.addSystem(new PlayerControlSystem(map), SystemPriorities.INPUT);

        // Then actors are processed, here other systems can run because of action processing
        engine.addSystem(new ActorSystem(), SystemPriorities.ACTOR);

        // rendering comes last.
        engine.addSystem(new RenderSystem(this, dungeon.width, dungeon.height), SystemPriorities.RENDER);
        engine.addSystem(new MessageLogSystem(createMessageField(), 6), SystemPriorities.RENDER);
    }

    private static function getRandomRoomPoint(room:Room):Vector
    {
        return {
            x: room.x + 1 + Std.random(room.grid.width - 2),
            y: room.y + 1 + Std.random(room.grid.height - 2)
        };
    }

    private static function getScaledBitmapData(path:String, scale:Int = 4):BitmapData
    {
        var orig:BitmapData = Assets.getBitmapData(path);
        var m:Matrix = new Matrix();
        m.scale(scale, scale);
        var result:BitmapData = new BitmapData(orig.width * scale, orig.height * scale, true, 0);
        result.draw(orig, m, null, null, null, false);
        return result;
    }

    private static inline function createTileImage(bmp:BitmapData, col:Int, row:Int):Image
    {
        return new Image(bmp, new Rectangle(col * Constants.TILE_SIZE, row * Constants.TILE_SIZE, Constants.TILE_SIZE, Constants.TILE_SIZE));
    }

    private static inline function createAnimation(bmp:BitmapData, frames:Array<Array<Int>>, frameRate:Float = 1):Image
    {
        var cols:Int = Std.int(bmp.width / Constants.TILE_SIZE);
        var spritemap:Spritemap = new Spritemap(bmp, Constants.TILE_SIZE, Constants.TILE_SIZE);
        var animFrames:Array<Int> = [];
        for (pair in frames)
            animFrames.push(pair[1] * cols + pair[0]);
        spritemap.add("", animFrames, frameRate);
        spritemap.play();
        return spritemap;
    }

    private static function renderDungeon(dungeon:Dungeon, tileset:BitmapData, transitionHelper:TransitionTileHelper):Graphic
    {
        var tilemapWidth:Int = dungeon.width * Constants.TILE_SIZE;
        var tilemapHeight:Int = dungeon.height * Constants.TILE_SIZE;

        var tilesetCols:Int = Math.floor(tileset.width / Constants.TILE_SIZE);
        var floorTilemap:Tilemap = new Tilemap(tileset, tilemapWidth, tilemapHeight, Constants.TILE_SIZE, Constants.TILE_SIZE);
        var wallTilemap:Tilemap = new Tilemap(tileset, tilemapWidth, tilemapHeight, Constants.TILE_SIZE, Constants.TILE_SIZE);

        var floorCol:Int = 4;
        var floorRow:Int = 0;
        var floorTileIndex:Int = tilesetCols * floorRow + floorCol;
        var wallRow:Int = 2;

        for (y in 0...dungeon.height)
        {
            for (x in 0...dungeon.width)
            {
                switch (dungeon.grid.get(x, y))
                {
                    case Floor, Door(_):
                        floorTilemap.setTile(x, y, floorTileIndex);

                    case Wall:
                        floorTilemap.setTile(x, y, floorTileIndex);

                        var wallCol:Int = transitionHelper.getTileNumber(dungeon.getWallTransition(x, y));
                        wallTilemap.setTile(x, y, tilesetCols * wallRow + wallCol);
                    default:
                        continue;
                }
            }
        }

        return new Graphiclist([floorTilemap, wallTilemap]);
    }

    /**
     * Create and add a textfield for displaying in-game messages
     **/

    private function createMessageField():TextField
    {
        var messageField:TextField = new TextField();
        messageField.width = HXP.width;
        messageField.mouseEnabled = false;
        messageField.selectable = false;
        messageField.embedFonts = true;
        messageField.defaultTextFormat = new TextFormat(Assets.getFont("eight2empire/eight2empire.ttf").fontName, 16, 0xFFFFFF);
        HXP.engine.addChild(messageField);
        return messageField;
    }

    /**
     * Update game entities and systems
     **/

    override public function update()
    {
        super.update();
        engine.update(HXP.elapsed);
    }
}


enum RoomDecor
{
    None;
    Library;
    Fountain;
    Light;
}

private typedef MonsterDefinition =
{
    var name:String;
    var tileRow:Int;
    var tileCol:Int;
    var hp:Int;
    var power:Int;
    var defense:Int;
}

private typedef WeaponDefinition =
{
    var name:String;
    var tileRow:Int;
    var tileCol:Int;
}
