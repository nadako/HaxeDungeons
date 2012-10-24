package dungeons;

import nme.display.DisplayObjectContainer;
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
import net.richardlord.ash.tick.FrameTickProvider;
import net.richardlord.ash.core.Entity;

import dungeons.components.LightSource;
import dungeons.components.CameraFocus;
import dungeons.components.Actor;
import dungeons.components.PlayerControls;
import dungeons.components.Renderable;
import dungeons.components.TileRenderable;
import dungeons.components.Position;

import dungeons.systems.SystemPriorities;
import dungeons.systems.MoveSystem;
import dungeons.systems.ActorSystem;
import dungeons.systems.CameraSystem;
import dungeons.systems.DungeonRenderSystem;
import dungeons.systems.LightingSystem;
import dungeons.systems.PlayerControlSystem;
import dungeons.systems.RenderSystem;

import dungeons.Dungeon;
import dungeons.ShadowCaster;

using dungeons.ArrayUtil;

class Main extends Sprite
{
    private static inline var TILE_SIZE:Int = 8;
    private static inline var HERO_SIGHT_RADIUS:Int = 10;

    private var dungeonTilesheet:Tilesheet;
    private var characterTilesheet:Tilesheet;

    private var dungeon:Dungeon;

    private var scene:Sprite;
    private var dungeonCanvas:Shape;
    private var lightCanvas:Shape;
    private var objectsContainer:DisplayObjectContainer;


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

        objectsContainer = new Sprite();
        scene.addChild(objectsContainer);

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

        var startRoom:Room = dungeon.rooms.randomChoice();

        var hero:Entity = new Entity();
        var heroDisplay:Shape = new Shape();
        characterTilesheet.drawTiles(heroDisplay.graphics, [0, 0, 0]);
        hero.add(new Renderable(heroDisplay));
        hero.add(new Position(startRoom.position.x + Std.int(startRoom.grid.getW() / 2), startRoom.position.y + Std.int(startRoom.grid.getH() / 2)));
        hero.add(new CameraFocus());
        hero.add(new PlayerControls());
        hero.add(new Actor(100));
        hero.add(new LightSource(HERO_SIGHT_RADIUS));
        game.addEntity(hero);

        game.addSystem(new PlayerControlSystem(this), SystemPriorities.INPUT);
        game.addSystem(new ActorSystem(), SystemPriorities.ACTOR);
        game.addSystem(new MoveSystem(dungeon.grid), SystemPriorities.MOVE);
        game.addSystem(new DungeonRenderSystem(dungeonCanvas.graphics, dungeonTilesheet, dungeon.grid), SystemPriorities.RENDER);
        game.addSystem(new RenderSystem(objectsContainer), SystemPriorities.RENDER);
        game.addSystem(new LightingSystem(lightCanvas.graphics, dungeon.grid), SystemPriorities.RENDER);
        game.addSystem(new CameraSystem(scene), SystemPriorities.RENDER);

        var tickProvider = new FrameTickProvider(this);
        tickProvider.add(game.update);
        tickProvider.start();
    }
}
