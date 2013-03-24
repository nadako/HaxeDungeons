package dungeons.systems;

import nme.geom.Rectangle;
import nme.display.BitmapData;
import nme.Lib;

import com.haxepunk.tweens.misc.NumTween;
import com.haxepunk.tweens.TweenEvent;
import com.haxepunk.tweens.motion.LinearMotion;
import com.haxepunk.graphics.Tilemap;
import com.haxepunk.graphics.Graphiclist;
import com.haxepunk.graphics.Canvas;
import com.haxepunk.graphics.Image;
import com.haxepunk.graphics.Spritemap;
import com.haxepunk.graphics.Text;
import com.haxepunk.HXP;
import com.haxepunk.Graphic;
import com.haxepunk.Scene;

import com.haxepunk.gui.Label;
import com.haxepunk.gui.MenuItem;
import com.haxepunk.gui.MenuList;

import ash.ObjectMap;
import ash.core.Engine;
import ash.core.NodeList;
import ash.core.System;

import dungeons.nodes.RenderNode;
import dungeons.components.Item;
import dungeons.components.Inventory;
import dungeons.components.Position.PositionChangeListener;
import dungeons.components.Health;
import dungeons.components.Fighter;
import dungeons.components.Renderable;
import dungeons.mapgen.Dungeon;
import dungeons.nodes.PlayerInventoryNode;
import dungeons.nodes.TimeTickerNode;
import dungeons.nodes.PlayerStatsNode;
import dungeons.utils.Grid;
import dungeons.utils.Map;
import dungeons.utils.TransitionTileHelper;

using dungeons.utils.EntityUtil;
using dungeons.utils.ArrayUtil;

class RenderSystem extends System
{
    private var map:Map;

    private var nodeList:NodeList<RenderNode>;
    private var positionListeners:ObjectMap<RenderNode, PositionChangeListener>;
    private var sceneEntities:ObjectMap<Renderable, RenderableEntity>;
    private var scene:Scene;

    private var assetFactory:AssetFactory;

    private var fovSystem:FOVSystem;
    private var fovOverlayData:BitmapData;
    private var fovOverlayImage:Image;
    private var fovOverlayEntity:com.haxepunk.Entity;
    private var fovOverlayDirty:Bool;

    private var memoryCanvas:Canvas;

    private var playerInventory:PlayerInventory;

    private var timeDisplay:Label;
    private var timeNodes:NodeList<TimeTickerNode>;

    public function new(scene:Scene, map:Map, dungeon:Dungeon, assetFactory:AssetFactory, renderSignals:RenderSignals)
    {
        super();
        this.scene = scene;
        this.map = map;
        this.assetFactory = assetFactory;
        renderSignals.hpChange.add(onHPChangeSignal);
        renderSignals.miss.add(onMissSignal);

        scene.addGraphic(renderDungeon(dungeon), RenderLayers.DUNGEON);
    }

    override public function addToEngine(engine:Engine):Void
    {
        positionListeners = new ObjectMap();

        sceneEntities = new ObjectMap();

        nodeList = engine.getNodeList(RenderNode);
        for (node in nodeList)
            onNodeAdded(node);
        nodeList.nodeAdded.add(onNodeAdded);
        nodeList.nodeRemoved.add(onNodeRemoved);

        fovSystem = engine.getSystem(FOVSystem);
        fovSystem.updated.add(onFOVUpdated);

        fovOverlayData = new BitmapData(map.width, map.height, true, 0xFF000000);

        fovOverlayImage = new Image(fovOverlayData);
        fovOverlayImage.scale = assetFactory.tileSize;
        fovOverlayEntity = scene.addGraphic(fovOverlayImage, RenderLayers.FOV);

        fovOverlayDirty = true;

        memoryCanvas = new Canvas(map.width * assetFactory.tileSize, map.height * assetFactory.tileSize);
        scene.addGraphic(memoryCanvas, RenderLayers.MEMORY);

        playerInventory = new PlayerInventory(engine.getNodeList(PlayerInventoryNode).head.inventory);
        scene.add(playerInventory);

        timeDisplay = new Label();
        timeDisplay.followCamera = true;
        timeDisplay.size = 16;
        timeDisplay.localX = HXP.width / 2;
        timeDisplay.color = 0xFFFFFF;
        scene.add(timeDisplay);
        timeNodes = engine.getNodeList(TimeTickerNode);
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        fovSystem.updated.remove(onFOVUpdated);
        scene.remove(fovOverlayEntity);

        nodeList.nodeAdded.remove(onNodeAdded);
        nodeList.nodeRemoved.remove(onNodeRemoved);
        nodeList = null;

        for (node in sceneEntities.keys())
            scene.remove(sceneEntities.get(node));
        sceneEntities = null;

        for (node in positionListeners.keys())
            node.position.changed.remove(positionListeners.get(node));
        positionListeners = null;

        timeNodes = null;
    }

    private function onFOVUpdated():Void
    {
        fovOverlayDirty = true;
    }

    private function redrawFOVOverlay():Void
    {
        var prevLightMap:Grid<Float> = fovSystem.prevLightMap;

        fovOverlayData.lock();
        var lightMap:Grid<Float> = fovSystem.currentLightMap;
        for (y in 0...lightMap.height)
        {
            for (x in 0...lightMap.width)
            {
                var intensity:Float = 0;

                var visible:Bool = false;
                var light:Float = lightMap.get(x, y);
                if (light > 0)
                {
                    intensity = 0.3 + 0.7 * light;
                    visible = true;
                }
                else if (fovSystem.inMemory(x, y))
                {
                    intensity = 0.3;
                }

                var color:Int = 0;
                if (intensity >= 1)
                    color = 0;
                else if (intensity == 0)
                    color = 0xFF000000;
                else
                    color = Std.int((1 - intensity) * 255) << 24;

                // uncomment the following to see overlay in red for debugging purposes
                // color |= 0x00FF0000;

                fovOverlayData.setPixel32(x, y, color);

                var wasVisible:Bool = prevLightMap.get(x, y) > 0;

                // show/hide sprite and update memory only if tile visibility has changed
                if ((wasVisible && !visible) || (!wasVisible && visible))
                {
                    var rect:Rectangle = new Rectangle(x * assetFactory.tileSize, y * assetFactory.tileSize, assetFactory.tileSize, assetFactory.tileSize);

                    // if it became visible - clear memory tile
                    if (!wasVisible)
                        memoryCanvas.fill(rect, 0, 0);

                    // for every renderable entity in this tile
                    for (e in map.get(x, y).entities)
                    {
                        var renderable:Renderable = e.get(Renderable);
                        if (renderable == null)
                            continue;

                        var sceneEntity:RenderableEntity = sceneEntities.get(renderable);

                        // update sprite visibility
                        if (visible)
                            sceneEntity.show();
                        else
                            sceneEntity.hide();

                        // if tile has just been hidden, draw memorable sprites to memory
                        if (wasVisible && renderable.memorable)
                            memoryCanvas.drawGraphic(Std.int(rect.x), Std.int(rect.y), sceneEntity.graphic);
                    }
                }
            }
        }
        fovOverlayData.unlock();
        fovOverlayImage.updateBuffer();
        fovOverlayDirty = false;
    }

    private function onNodeAdded(node:RenderNode):Void
    {
        var listener:PositionChangeListener = callback(onNodePositionChanged, node);
        node.position.changed.add(listener);
        positionListeners.set(node, listener);

        var entity:RenderableEntity = scene.add(new RenderableEntity(node.renderable, assetFactory));
        sceneEntities.set(node.renderable, entity);

        // TODO: hackity hack. refactor this to the health manager
        var health:Health = node.entity.get(Health);
        if (health != null)
            entity.addGraphic(new HealthBar(assetFactory.tileSize, health));

        entity.x = node.position.x * assetFactory.tileSize;
        entity.y = node.position.y * assetFactory.tileSize;
    }

    private function onNodeRemoved(node:RenderNode):Void
    {
        var listener:PositionChangeListener = positionListeners.get(node);
        node.position.changed.remove(listener);

        scene.remove(sceneEntities.get(node.renderable));
        sceneEntities.remove(node.renderable);
    }

    private function onNodePositionChanged(node:RenderNode, oldX:Int, oldY:Int):Void
    {
        var entity:RenderableEntity = sceneEntities.get(node.renderable);
        entity.x = node.position.x * assetFactory.tileSize;
        entity.y = node.position.y * assetFactory.tileSize;

        if (fovSystem.currentLightMap.get(node.position.x, node.position.y) > 0)
            entity.show();
        else
            entity.hide();
    }

    override public function update(time:Float):Void
    {
        if (fovOverlayDirty)
            redrawFOVOverlay();

        if (timeNodes.head != null)
            timeDisplay.text = Std.string(timeNodes.head.ticker.ticks);
    }

    private function onHPChangeSignal(posX:Int, posY:Int, value:Int):Void
    {
        var color:Int = 0xFF0000;
        var text:String = Std.string(value);
        if (value > 0)
        {
            text = ("+" + text);
            color = 0x00FF00;
        }
        addFloatingText(text, color, posX, posY);
    }

    private function onMissSignal(posX:Int, posY:Int):Void
    {
        addFloatingText("Miss!", 0xFF0000, posX, posY);
    }

    private inline function addFloatingText(text:String, color:Int, posX:Int, posY:Int):Void
    {
        scene.create(FloatingText).init(assetFactory.tileSize, text, color, posX, posY);
    }

    private function renderDungeon(dungeon:Dungeon):Graphic
    {
        var transitionHelper:TransitionTileHelper = new TransitionTileHelper("eight2empire_transitions.json");

        var tilemapWidth:Int = dungeon.width * assetFactory.tileSize;
        var tilemapHeight:Int = dungeon.height * assetFactory.tileSize;
        var bmp:BitmapData = assetFactory.getImage("eight2empire/level assets.png");

        var tilesetCols:Int = Math.floor(bmp.width / assetFactory.tileSize);
        var floorTilemap:Tilemap = new Tilemap(bmp, tilemapWidth, tilemapHeight, assetFactory.tileSize, assetFactory.tileSize);
        var wallTilemap:Tilemap = new Tilemap(bmp, tilemapWidth, tilemapHeight, assetFactory.tileSize, assetFactory.tileSize);

        var wallRow:Int = 2 + Std.random(5) * 2;
        var floorCol:Int = Std.random(15);
        var floorRow:Int = 0;
        var floorTileIndex:Int = tilesetCols * floorRow + floorCol;

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
}

class RenderLayers
{
    public static inline var DUNGEON:Int = HXP.BASELAYER;
    public static inline var MEMORY:Int = HXP.BASELAYER - 1;
    public static inline var OBJECT:Int = HXP.BASELAYER - 2;
    public static inline var CHARACTER:Int = HXP.BASELAYER - 3;
    public static inline var FOV:Int = HXP.BASELAYER - 4;
    public static inline var UI:Int = HXP.BASELAYER - 5;
}

private class RenderableEntity extends com.haxepunk.Entity
{
    private var renderable:Renderable;
    private var assetFactory:AssetFactory;
    private var mainGraphic:Graphic;
    private var alphaTween:NumTween;

    public function new(renderable:Renderable, assetFactory:AssetFactory)
    {
        super();
        graphic = new Graphiclist();
        layer = renderable.layer;
        this.renderable = renderable;
        this.assetFactory = assetFactory;

        if (!renderable.memorable)
        {
            alphaTween = new NumTween(onAlphaTweenComplete);
            alphaTween.value = 0;
            addTween(alphaTween);
        }
    }

    public function show():Void
    {
        visible = true;
        if (!renderable.memorable)
            alphaTween.tween(alphaTween.value, 1.0, 0.25);
    }

    public function hide():Void
    {
        if (!renderable.memorable)
            alphaTween.tween(alphaTween.value, 0.0, 0.25);
        else
            visible = false;
    }

    private function onAlphaTweenComplete(e):Void
    {
        if (alphaTween.value == 0)
            visible = false;
    }

    override public function update():Void
    {
        if (alphaTween != null && alphaTween.active)
        {
            for (g in cast(graphic, Graphiclist).children)
            {
                if (Std.is(g, Image))
                    cast(g, Image).alpha = alphaTween.value;
                else if (Std.is(g, Spritemap))
                    cast(g, Spritemap).alpha = alphaTween.value;
            }
        }

        if (renderable.assetInvalid)
        {
            var gList:Graphiclist = cast graphic;

            if (mainGraphic != null)
                gList.remove(mainGraphic);

            mainGraphic = assetFactory.createTileImage(renderable.assetName);
            gList.add(mainGraphic);

            renderable.assetInvalid = false;
        }
    }
}

private class FloatingText extends com.haxepunk.Entity
{
    private var tween:LinearMotion;

    public function new()
    {
        super();
        layer = RenderLayers.UI;
        tween = new LinearMotion();
    }

    public function init(tileSize:Int, text:String, color:Int, posX:Int, posY:Int):Void
    {
        var textGraphic:Text = new Text(text, 0, 0, 0, 0, {color: color});
        graphic = textGraphic;

        var origX:Int = posX * tileSize + Std.int(tileSize * 0.5 - textGraphic.width * 0.5);
        var origY:Int = posY * tileSize - textGraphic.height;
        var targetX:Int = origX + ((Math.random() < 0.5) ? -1 : 1) * Std.int(tileSize * Math.random() * 0.5);
        var targetY:Int = origY - Std.int(tileSize * (0.5 + Math.random() * 0.5));

        x = origX;
        y = origY;

        tween.setMotion(origX, origY, targetX, targetY, 0.5);
        tween.addEventListener(TweenEvent.FINISH, onTweenComplete);
        addTween(tween);
    }

    private function onTweenComplete(event:TweenEvent):Void
    {
        tween.removeEventListener(TweenEvent.FINISH, onTweenComplete);
        removeTween(tween);
        scene.recycle(this);
    }

    override public function update():Void
    {
        if (tween.active)
        {
            x = tween.x;
            y = tween.y;
        }
    }
}

private class HealthBar extends Canvas
{
    private static inline var WIDTH_PERCENT:Float = 1.2;
    private static inline var HEIGHT:Int = 2;
    private static inline var BORDER:Int = 1;
    private static inline var BORDER_COLOR:Int = 0x363636;
    private static inline var MARGIN:Int = 2;
    private static inline var ALPHA:Float = 1;// 0.8;
    private static inline var FILL_COLOR:Int = 0xFF0000;
    private static inline var EMPTY_COLOR:Int = 0x000000;
    private static inline var TWEEN_DURATION:Float = 0.25;

    private var health:Health;
    private var tween:NumTween;

    public function new(parentWidth:Int, health:Health)
    {
        var width:Int = Std.int(parentWidth * WIDTH_PERCENT) + BORDER * 2;
        super(width, HEIGHT + BORDER * 2);
        x = -(width - parentWidth) / 2;
        y = -(height + MARGIN);
        alpha = ALPHA;

        this.health = health;
        this.health.updated.add(onHealthUpdate);

        active = true;
        tween = new NumTween();
        tween.value = health.currentHP / health.maxHP;
        HXP.scene.addTween(tween);

        redraw();
    }

    private function onHealthUpdate():Void
    {
        tween.tween(tween.value, health.currentHP / health.maxHP, TWEEN_DURATION);
    }

    private function redraw():Void
    {
        var percent:Float = tween.value;
        var rect:Rectangle = HXP.rect;

        // draw border, if any
        if (BORDER > 0)
        {
            rect.x = rect.y = 0;
            rect.width = width;
            rect.height = height;
            fill(rect, BORDER_COLOR);
        }

        // fill health bar
        var w:Int = Std.int((width - BORDER * 2) * percent);
        rect.x = rect.y = BORDER;
        rect.height = HEIGHT;
        rect.width = w;
        fill(rect, FILL_COLOR);

        // draw empty bar part (if health is not full)
        if (percent < 1)
        {
            rect.x += rect.width;
            rect.width = Math.ceil((width - BORDER * 2) * (1 - percent));
            fill(rect, EMPTY_COLOR);
        }
    }

    override public function update():Void
    {
        if (tween.active)
            redraw();
    }

    public function dispose():Void
    {
        HXP.scene.removeTween(tween);

        health.updated.remove(onHealthUpdate);
        health = null;
    }
}

private class PlayerInventory extends MenuList
{
    private static inline var WIDTH:Int = 100;

    private var inventory:Inventory;

    public function new(inventory:Inventory)
    {
        super(HXP.width - WIDTH - MenuList.defaultPadding * 2, 0, WIDTH);
        followCamera = true;
        enabled = false;
        addControl(new MenuItem("Inventory", null, 0, 0, 0, WIDTH));

        this.inventory = inventory;
        inventory.updated.add(redraw);
        redraw();
    }

    private function redraw():Void
    {
        if (inventory.items.length > 0)
        {
            show();

            var len:Int = children.length;
            while (len > 1)
            {
                len--;
                removeControl(children[len]);
            }

            for (entity in inventory.items)
            {
                var name:String = entity.getName();
                var item:Item = entity.get(Item);
                addControl(new MenuItem(name, null, item.quantity > 1 ? item.quantity : 0, 0, 0, WIDTH));
            }
        }
        else
        {
            hide();
        }
    }
}