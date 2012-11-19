package dungeons;

import nme.display.Bitmap;
import nme.ObjectHash;
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

import de.polygonal.ds.Array2;

import net.richardlord.ash.core.Game;
import net.richardlord.ash.tick.FrameTickProvider;
import net.richardlord.ash.core.Entity;

import dungeons.components.Description;
import dungeons.components.MonsterAI;
import dungeons.components.Obstacle;
import dungeons.components.FOV;
import dungeons.components.CameraFocus;
import dungeons.components.Actor;
import dungeons.components.PlayerControls;
import dungeons.components.Renderable;
import dungeons.components.Position;
import dungeons.components.LightOccluder;
import dungeons.components.DoorRenderable;
import dungeons.components.Door;
import dungeons.components.Fighter;

import dungeons.systems.MessageLogSystem;
import dungeons.systems.FightSystem;
import dungeons.systems.MonsterAISystem;
import dungeons.systems.SystemPriorities;
import dungeons.systems.MoveSystem;
import dungeons.systems.ActorSystem;
import dungeons.systems.CameraSystem;
import dungeons.systems.FOVSystem;
import dungeons.systems.PlayerControlSystem;
import dungeons.systems.RenderSystem;
import dungeons.systems.ObstacleSystem;
import dungeons.systems.DoorSystem;

import dungeons.render.RenderLayer;
import dungeons.render.Tilesheet;

import dungeons.Dungeon;
import dungeons.ShadowCaster;
import dungeons.Eight2Empire;

using dungeons.ArrayUtil;

class Main extends Sprite
{
    private var targetBitmap:Bitmap;
    private var targetBitmapData:BitmapData;

    private var dungeon:Dungeon;

    public function new()
    {
        super();
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(event:Event):Void
    {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

        var dungeonTilesheet:Tilesheet = new Tilesheet(Assets.getBitmapData("eight2empire/level assets.png"), Constants.TILE_SIZE, Constants.TILE_SIZE);
        var characterTilesheet:Tilesheet = new Tilesheet(Assets.getBitmapData("oryx_lofi/lofi_char.png"), Constants.TILE_SIZE, Constants.TILE_SIZE);

        var game:Game = new Game();

        var obstacle:Obstacle = new Obstacle();
        var lightOccluder:LightOccluder = new LightOccluder();

        var renderedWalls:BitmapData = new BitmapData(25 * Constants.TILE_SIZE, Constants.TILE_SIZE);
        var renderedWallsCache:IntHash<Bool> = new IntHash();
        var wallTilesheet:Tilesheet = new Tilesheet(renderedWalls, Constants.TILE_SIZE, Constants.TILE_SIZE);
        var tmpPoint:Point = new Point(0, 0);

        var dungeonWidth:Int = 50;
        var dungeonHeight:Int = 50;

        dungeon = new Dungeon(new Array2Cell(dungeonWidth, dungeonHeight), 25, new Array2Cell(5, 5), new Array2Cell(20, 20));
        dungeon.generate();

        var openDoorRenderer = new TilesheetRenderer(dungeonTilesheet, 2, 31);
        var closedDoorRenderer = new TilesheetRenderer(dungeonTilesheet, 2, 30);

        for (y in 0...dungeonHeight)
        {
            for (x in 0...dungeonWidth)
            {
                var entity:Entity = new Entity();
                game.addEntity(entity);
                entity.add(new Position(x, y));

                switch (dungeon.grid.get(x, y))
                {
                    case Wall:
                        entity.add(obstacle);
                        entity.add(lightOccluder);

                        var col:Int = Eight2Empire.getTileNumber(dungeon.getWallTransition(x, y));
                        if (!renderedWallsCache.exists(col))
                        {
                            tmpPoint.x = Constants.TILE_SIZE * col;
                            dungeonTilesheet.draw(renderedWalls, 4, 0, tmpPoint);
                            dungeonTilesheet.draw(renderedWalls, col, 2, tmpPoint);
                            renderedWallsCache.set(col, true);
                        }

                        entity.add(new Renderable(RenderLayer.Dungeon, new TilesheetRenderer(wallTilesheet, col, 0)));
                    case Floor:
                        entity.add(new Renderable(RenderLayer.Dungeon, new TilesheetRenderer(dungeonTilesheet, 4, 0)));
                    case Door(open):
                        entity.add(new Renderable(RenderLayer.Dungeon, new TilesheetRenderer(dungeonTilesheet, 4, 0)));

                        var door:Entity = new Entity();
                        door.add(new dungeons.components.Door(open));
                        door.add(new Position(x, y));
                        door.add(new DoorRenderable(openDoorRenderer, closedDoorRenderer), Renderable);
                        game.addEntity(door);
                    default:
                        continue;
                }
            }
        }

        var startRoom:Room = dungeon.rooms.randomChoice();

        var hero:Entity = new Entity();
        hero.name = "player";
        hero.add(new Renderable(RenderLayer.Player, new TilesheetRenderer(characterTilesheet, 1, 0)));
        hero.add(new Position(startRoom.position.x + Std.int(startRoom.grid.getW() / 2), startRoom.position.y + Std.int(startRoom.grid.getH() / 2)));
        hero.add(new CameraFocus());
        hero.add(new PlayerControls());
        hero.add(new Actor(100));
        hero.add(new FOV(10));
        hero.add(new Fighter(10, 3, 2));
        hero.add(obstacle);
        game.addEntity(hero);

        var monsterAI = new MonsterAI();
        var monsterDescription = new Description("Skeleton");
        for (room in dungeon.rooms)
        {
            var feature:RoomFeature = Type.allEnums(RoomFeature).randomChoice();
            switch (feature)
            {
                case Library:
                    var y:Int = room.position.y + 1;
                    for (x in room.position.x + 1...room.position.x + room.grid.getW() - 1)
                    {
                        if (Math.random() < 0.25)
                            continue;

                        if (x == room.position.x + 1 && dungeon.grid.get(x - 1, y) != Tile.Wall)
                            continue;

                        if (x == room.position.x + room.grid.getW() - 2 && dungeon.grid.get(x + 1, y) != Tile.Wall)
                            continue;

                        if (dungeon.grid.get(x, y - 1) != Tile.Wall)
                            continue;

                        var shelf:Entity = new Entity();
                        shelf.add(new Position(x, y));
                        shelf.add(obstacle);
                        shelf.add(new Renderable(RenderLayer.Dungeon, new TilesheetRenderer(dungeonTilesheet, 14 + Std.random(6), 22)));
                        game.addEntity(shelf);
                    }
                case Fountain:

                    var fountain:Entity = new Entity();
                    fountain.add(new Position(room.position.x + Std.int(room.grid.getW() / 2), Std.int(room.position.y + room.grid.getH() / 2)));
                    fountain.add(obstacle);
                    fountain.add(new Renderable(RenderLayer.Dungeon, new TilesheetRenderer(dungeonTilesheet, 15, 28)));
                    game.addEntity(fountain);

                default:
            }

            if (room != startRoom)
            {
                var monster:Entity = new Entity();
                monster.add(monsterDescription);
                monster.add(new Renderable(RenderLayer.NPC, new TilesheetRenderer(characterTilesheet, Std.random(3), 6)));
                monster.add(new Position(room.position.x + Std.int(room.grid.getW() / 2), room.position.y + Std.int(room.grid.getH() / 2)));
                monster.add(new Actor(100));
                monster.add(new Fighter(10, 1 + Std.random(2), Std.random(3)));
                monster.add(monsterAI);
                monster.add(obstacle);
                game.addEntity(monster);
            }
        }

        var zoom:Float = 4;

        var viewport:Rectangle = new Rectangle(0, 0, stage.stageWidth / zoom, stage.stageHeight / zoom);
        targetBitmapData = new BitmapData(Std.int(viewport.width), Std.int(viewport.height));
        targetBitmap = new Bitmap(targetBitmapData);
        targetBitmap.scaleX = targetBitmap.scaleY = zoom;
        addChild(targetBitmap);

        var messageField:TextField = new TextField();
        messageField.width = stage.stageWidth;
        messageField.mouseEnabled = false;
        messageField.selectable = false;
        messageField.embedFonts = true;
        messageField.defaultTextFormat = new TextFormat(Assets.getFont("eight2empire/eight2empire.ttf").fontName, 16, 0xFFFFFF);
        addChild(messageField);

        game.addSystem(new MonsterAISystem(), SystemPriorities.INPUT);
        game.addSystem(new ActorSystem(), SystemPriorities.ACTOR);
        game.addSystem(new ObstacleSystem(dungeonWidth, dungeonHeight), SystemPriorities.NONE);
        game.addSystem(new FOVSystem(dungeonWidth, dungeonHeight), SystemPriorities.NONE);
        game.addSystem(new MoveSystem(), SystemPriorities.NONE);
        game.addSystem(new CameraSystem(viewport), SystemPriorities.NONE);
        game.addSystem(new RenderSystem(targetBitmapData, viewport, dungeonWidth, dungeonHeight), SystemPriorities.RENDER);
        game.addSystem(new DoorSystem(), SystemPriorities.NONE);
        game.addSystem(new FightSystem(), SystemPriorities.NONE);
        game.addSystem(new PlayerControlSystem(this), SystemPriorities.INPUT);
        game.addSystem(new MessageLogSystem(messageField, 6), SystemPriorities.RENDER);

        var tickProvider = new FrameTickProvider(this);
        tickProvider.add(game.update);
        tickProvider.start();
    }
}

enum RoomFeature
{
    None;
    Library;
    Fountain;
    Light;
}
