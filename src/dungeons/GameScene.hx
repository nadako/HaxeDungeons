package dungeons;

import Lambda;

import flash.net.FileReference;

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

import dungeons.components.HealthRegen;
import dungeons.components.Key;
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
import dungeons.components.TimeTicker;
import dungeons.components.Equipment;

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
import dungeons.systems.RenderSignals;
import dungeons.systems.TimeSystem;
import dungeons.systems.ScheduleSystem;
import dungeons.systems.HealthRegenSystem;

import dungeons.mapgen.Dungeon;
import dungeons.utils.ShadowCaster;
import dungeons.utils.TransitionTileHelper;
import dungeons.utils.MapGrid;
import dungeons.utils.Vector;
import dungeons.utils.Scheduler;

using dungeons.utils.ArrayUtil;

class GameScene extends Scene
{
    private var engine:Engine;
    private var renderSystem:RenderSystem;

    public function new()
    {
        super();
    }

    private function createDOT(dungeon:Dungeon):String
    {
        var lines:Array<String> = [];
        lines.push("digraph dungeon {");

        for (i in 0...dungeon.rooms.length)
        {
            var room:Room = dungeon.rooms[i];
            for (conn in room.connections)
            {
                var j:Int = Lambda.indexOf(dungeon.rooms, conn.toRoom);
                var style:String = Lambda.indexOf(room.unusedConnections, conn) == -1 ? "solid" : "dotted";
                var tailport:String = null;
                var headport:String = null;
                switch (conn.direction)
                {
                    case North:
                        tailport = "n";
                        headport = "s";
                    case South:
                        tailport = "s";
                        headport = "n";
                    case East:
                        tailport = "e";
                        headport = "w";
                    case West:
                        tailport = "w";
                        headport = "e";
                    default:
                        throw "WTF";
                };
                lines.push('\tr$i -> r$j [label="${conn.toRoom.level}", style="$style", tailport=$tailport, headport=$headport];');
            }
        }

        lines.push("}");
        return lines.join("\n");
    }

    override public function begin()
    {
        engine = new Engine();

        var entityCreator:EntityCreator = new EntityCreator(engine);

        var dungeon:Dungeon = new Dungeon(50, 50, 7, {x: 5, y: 5}, {x: 10, y: 10});
        dungeon.generate();

        var ref:FileReference = new FileReference();
        ref.save(createDOT(dungeon), "dungeon.gv");

        var map:MapGrid = new MapGrid(dungeon.width, dungeon.height);

        var assetFactory:AssetFactory = new AssetFactory("tileset.json");

        // marker components can easily be a reusable single instance
        var lightOccluder:LightOccluder = new LightOccluder();
        var obstacle:Obstacle = new Obstacle();

        var doorTypes:Array<String> = "curtain,shabby,simple,peephole,square,braced,iron,iron_peephole,grated,gold,gold_peephole".split(",");

        var startRoom:Room = dungeon.rooms[0];

        var endRoomCandidates:Array<Room> = [];
        for (room in dungeon.getLevelRooms(dungeon.keyLevel))
        {
            if (room == startRoom)
                continue;
            if (room.children.length == 0)
                endRoomCandidates.push(room);
        }

        var endRoom:Room = endRoomCandidates.randomChoice();
        var endPoint:Vector = getRandomRoomPoint(endRoom);

        var downStairs:Entity = new Entity();
        downStairs.add(new Position(endPoint.x, endPoint.y));
        downStairs.add(new Renderable("stair_down", RenderLayers.OBJECT));
        engine.addEntity(downStairs);

        for (y in 0...dungeon.height)
        {
            for (x in 0...dungeon.width)
            {
                switch (dungeon.grid.get(x, y).tile)
                {
                    case Wall:
                        var entity:Entity = new Entity();
                        entity.add(new Position(x, y));
                        entity.add(obstacle);
                        entity.add(lightOccluder);
                        engine.addEntity(entity);
                    case Door(open, level):
                        var door:Entity = new Entity();
                        door.add(new Position(x, y));
                        door.add(new dungeons.components.Door(open, level));
                        var type:String = doorTypes[level % doorTypes.length];
                        door.add(new DoorRenderable("door_"+type+"_open", "door_"+type+"_closed"), Renderable);
                        engine.addEntity(door);
                    default:
                        continue;
                }
            }
        }

        for (keyLevel in 0...dungeon.keyLevel)
        {
            var rooms:Array<Room> = Lambda.array(dungeon.getLevelRooms(keyLevel));
            rooms.sort(function (a:Room, b:Room) {
                if (a.intensity > b.intensity)
                    return -1;
                if (a.intensity < b.intensity)
                    return 1;
                return 0;
            });

            var room:Room = rooms[0];
            var point:Vector = getRandomRoomPoint(room);

            var key:Entity = new Entity();
            key.add(new Position(point.x, point.y));
            key.add(new Item("key"+(keyLevel + 1), false, 1));
            key.add(new Description("Key " + (keyLevel + 1)));
            key.add(new Key(keyLevel + 1));

            var assetName:String = "key" + Std.string(keyLevel % 3 + 1);
            key.add(new Renderable(assetName, RenderLayers.OBJECT));

            engine.addEntity(key);
        }

        for (room in dungeon.rooms)
        {
            var randomPoint:Vector;

            if (room != startRoom && HXP.random < 0.3)
            {
                randomPoint = getRandomRoomPoint(room);
                var monster:Entity = entityCreator.createMonster();
                monster.get(Position).moveTo(randomPoint.x, randomPoint.y);
            }

            if (HXP.random < 0.3)
            {
                randomPoint = getRandomRoomPoint(room);
                var gold:Entity = entityCreator.createGold(1 + HXP.rand(30));
                gold.get(Position).moveTo(randomPoint.x, randomPoint.y);
            }

            if (HXP.random < 0.3)
            {
                randomPoint = getRandomRoomPoint(room);
                var weapon:Entity = entityCreator.createWeapon();
                weapon.get(Position).moveTo(randomPoint.x, randomPoint.y);
            }

            if (HXP.random < 0.3)
            {
                randomPoint = getRandomRoomPoint(room);
                var remains:Entity = entityCreator.createRemains();
                remains.get(Position).moveTo(randomPoint.x, randomPoint.y);
            }

            var decor:RoomDecor = RoomDecor.randomChoice();
            switch (decor)
            {
                case Library:
                    var y:Int = room.y + 1;
                    for (x in room.x + 1...room.x + room.grid.width - 1)
                    {
                        if (HXP.random < 0.1)
                            continue;

                        if (x == room.x + 1 && dungeon.grid.get(x - 1, y).tile != Tile.Wall)
                            continue;

                        if (x == room.x + room.grid.width - 2 && dungeon.grid.get(x + 1, y).tile != Tile.Wall)
                            continue;

                        if (dungeon.grid.get(x, y - 1).tile != Tile.Wall)
                            continue;

                        var shelf:Entity = new Entity();
                        shelf.add(new Position(x, y));
                        shelf.add(obstacle);
                        var type:String = HXP.random < 0.5 ? "bookshelf_ransacked" : "bookshelf";
                        var variant:Int = HXP.rand(3);
                        shelf.add(new Renderable(type+variant, RenderLayers.OBJECT));
                        engine.addEntity(shelf);
                    }
                case Fountain:
                    var fountain:Entity = new Entity();
                    fountain.add(new Position(room.x + Std.int(room.grid.width / 2), Std.int(room.y + room.grid.height / 2)));
                    fountain.add(obstacle);
                    fountain.add(new Renderable("waterbowl", RenderLayers.OBJECT));
                    engine.addEntity(fountain);
                case Light:
                    var light:Entity = new Entity();
                    light.add(new Position(room.x + Std.int(room.grid.width / 2), Std.int(room.y + room.grid.height / 2)));
                    light.add(obstacle);
                    light.add(new Renderable("firebowl", RenderLayers.OBJECT));
                    engine.addEntity(light);
                default:
            }
        }

        var timeTicker:Entity = new Entity();
        timeTicker.add(new TimeTicker());
        engine.addEntity(timeTicker);

        var startPoint:Vector = getRandomRoomPoint(startRoom);
        var hero:Entity = entityCreator.createPlayer();
        hero.get(Position).moveTo(startPoint.x, startPoint.y);

        var upStairs:Entity = new Entity();
        upStairs.add(new Position(startPoint.x, startPoint.y));
        upStairs.add(new Renderable("stair_up", RenderLayers.OBJECT));
        engine.addEntity(upStairs);

        var renderSignals:RenderSignals = new RenderSignals();

        var scheduler:Scheduler = new Scheduler();

        // These systems don't do anything on ticks, instead they react on signals
        engine.addSystem(new MonsterAISystem(map), SystemPriorities.NONE);
        engine.addSystem(new ObstacleSystem(map), SystemPriorities.NONE);
        engine.addSystem(new FOVSystem(map), SystemPriorities.NONE);
        engine.addSystem(new PositionSystem(map), SystemPriorities.NONE);
        engine.addSystem(new CameraSystem(assetFactory.tileSize), SystemPriorities.NONE);
        engine.addSystem(new DoorSystem(map), SystemPriorities.NONE);
        engine.addSystem(new FightSystem(renderSignals), SystemPriorities.NONE);
        engine.addSystem(new HealthRegenSystem(scheduler, renderSignals), SystemPriorities.NONE);
        engine.addSystem(new InventorySystem(), SystemPriorities.NONE);
        engine.addSystem(new TimeSystem(scheduler), SystemPriorities.NONE);
        engine.addSystem(new ActorSystem(scheduler), SystemPriorities.NONE);

        // Input system runs first
        engine.addSystem(new PlayerControlSystem(map), SystemPriorities.INPUT);

        // Then action scheduling/processing is performed. This is where
        // other systems are called through signals.
        engine.addSystem(new ScheduleSystem(scheduler), SystemPriorities.ACTIONS);

        // rendering comes last.
        engine.addSystem(new RenderSystem(this, map, dungeon, assetFactory, renderSignals, scheduler), SystemPriorities.RENDER);
        engine.addSystem(new MessageLogSystem(createMessageField(), 6), SystemPriorities.RENDER);
    }

    private static function getRandomRoomPoint(room:Room):Vector
    {
        return {
            x: room.x + 1 + HXP.rand(room.grid.width - 2),
            y: room.y + 1 + HXP.rand(room.grid.height - 2)
        };
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
        engine.update(HXP.elapsed);
        super.update();
    }
}


enum RoomDecor
{
    None;
    Library;
    Fountain;
    Light;
}
