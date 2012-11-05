package dungeons;

import nme.display.Bitmap;
import nme.ObjectHash;
import nme.display.DisplayObjectContainer;
import nme.events.KeyboardEvent;
import nme.ui.Keyboard;
import nme.display.Shape;
import nme.Assets;
import nme.geom.Rectangle;
import nme.geom.Matrix;
import nme.events.Event;
import nme.display.BitmapData;
import nme.display.StageScaleMode;
import nme.display.Sprite;
import nme.Lib;

import de.polygonal.ds.Array2;

import net.richardlord.ash.core.Game;
import net.richardlord.ash.tick.FrameTickProvider;
import net.richardlord.ash.core.Entity;

import dungeons.components.MonsterAI;
import dungeons.components.Obstacle;
import dungeons.components.Move;
import dungeons.components.FOV;
import dungeons.components.CameraFocus;
import dungeons.components.Actor;
import dungeons.components.PlayerControls;
import dungeons.components.Renderable;
import dungeons.components.Position;
import dungeons.components.LightOccluder;

import dungeons.systems.MonsterAISystem;
import dungeons.systems.SystemPriorities;
import dungeons.systems.MoveSystem;
import dungeons.systems.ActorSystem;
import dungeons.systems.CameraSystem;
import dungeons.systems.FOVSystem;
import dungeons.systems.PlayerControlSystem;
import dungeons.systems.RenderSystem;
import dungeons.systems.ObstacleSystem;

import dungeons.render.RenderLayer;
import dungeons.render.Tilesheet;

import dungeons.Dungeon;
import dungeons.ShadowCaster;

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

        var dungeonTilesheet:Tilesheet = new Tilesheet(Assets.getBitmapData("oryx_lofi/lofi_environment.png"), Constants.TILE_SIZE, Constants.TILE_SIZE);
        var characterTilesheet:Tilesheet = new Tilesheet(Assets.getBitmapData("oryx_lofi/lofi_char.png"), Constants.TILE_SIZE, Constants.TILE_SIZE);

        var game:Game = new Game();

        var obstacle:Obstacle = new Obstacle();
        var lightOccluder:LightOccluder = new LightOccluder();

        dungeon = new Dungeon(new Array2Cell(50, 50), 25, new Array2Cell(5, 5), new Array2Cell(20, 20));
        dungeon.generate();
        for (y in 0...dungeon.grid.getH())
        {
            for (x in 0...dungeon.grid.getW())
            {
                var col:Int = 0;
                var row:Int = 2;

                var entity:Entity = new Entity();
                entity.add(new Position(x, y));

                switch (dungeon.grid.get(x, y))
                {
                    case Wall:
                        if (dungeon.grid.inRange(x, y + 1) && dungeon.grid.get(x, y + 1) == Wall)
                            col = 4;
                        entity.add(obstacle);
                        entity.add(lightOccluder);
                    case Floor:
                        col = 5;
                    default:
                        continue;
                }

                entity.add(new Renderable(RenderLayer.Dungeon, new TilesheetRenderer(dungeonTilesheet, col, row)));
                game.addEntity(entity);
            }
        }

        var startRoom:Room = dungeon.rooms.randomChoice();

        var hero:Entity = new Entity();
        hero.add(new Renderable(RenderLayer.Player, new TilesheetRenderer(characterTilesheet, 1, 0)));
        hero.add(new Position(startRoom.position.x + Std.int(startRoom.grid.getW() / 2), startRoom.position.y + Std.int(startRoom.grid.getH() / 2)));
        hero.add(new CameraFocus());
        hero.add(new PlayerControls());
        hero.add(new Actor(100));
        hero.add(new FOV(10));
        hero.add(obstacle);
        game.addEntity(hero);

        var monsterAI = new MonsterAI();
        for (room in dungeon.rooms)
        {
            if (room == startRoom)
                continue;

            var monster:Entity = new Entity();
            monster.add(new Renderable(RenderLayer.NPC, new TilesheetRenderer(characterTilesheet, Std.random(3), 6)));
            monster.add(new Position(room.position.x + Std.int(room.grid.getW() / 2), room.position.y + Std.int(room.grid.getH() / 2)));
            monster.add(new Actor(100));
            monster.add(monsterAI);
            monster.add(obstacle);
            game.addEntity(monster);
        }

        var zoom:Float = 4;

        var viewport:Rectangle = new Rectangle(0, 0, stage.stageWidth / zoom, stage.stageHeight / zoom);
        targetBitmapData = new BitmapData(Std.int(viewport.width), Std.int(viewport.height));
        targetBitmap = new Bitmap(targetBitmapData);
        targetBitmap.scaleX = targetBitmap.scaleY = zoom;
        addChild(targetBitmap);

        game.addSystem(new PlayerControlSystem(this), SystemPriorities.INPUT);
        game.addSystem(new MonsterAISystem(), SystemPriorities.INPUT);
        game.addSystem(new ActorSystem(), SystemPriorities.ACTOR);
        game.addSystem(new ObstacleSystem(dungeon.grid.getW(), dungeon.grid.getH()), SystemPriorities.MOVE);
        game.addSystem(new FOVSystem(dungeon.grid.getW(), dungeon.grid.getH()), SystemPriorities.MOVE);
        game.addSystem(new MoveSystem(), SystemPriorities.MOVE);
        game.addSystem(new CameraSystem(viewport), SystemPriorities.RENDER);
        game.addSystem(new RenderSystem(targetBitmapData, viewport, dungeon.grid.getW(), dungeon.grid.getH()), SystemPriorities.RENDER);

        var tickProvider = new FrameTickProvider(this);
        tickProvider.add(game.update);
        tickProvider.start();
    }
}
