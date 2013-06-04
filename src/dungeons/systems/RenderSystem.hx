package dungeons.systems;

import flash.geom.Rectangle;
import flash.display.BitmapData;

import com.haxepunk.tweens.misc.NumTween;
import com.haxepunk.tweens.motion.LinearMotion;
import com.haxepunk.tweens.TweenEvent;
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
import com.haxepunk.gui.Panel;

import ash.core.Engine;
import ash.core.NodeList;
import ash.core.System;

import dungeons.nodes.RenderNode;
import dungeons.components.Item;
import dungeons.components.Inventory;
import dungeons.components.Position.PositionChangeListener;
import dungeons.components.Health;
import dungeons.components.Renderable;
import dungeons.mapgen.Dungeon;
import dungeons.nodes.PlayerInventoryNode;
import dungeons.nodes.TimeTickerNode;
import dungeons.utils.Grid;
import dungeons.utils.MapGrid;
import dungeons.utils.TransitionTileHelper;
import dungeons.utils.Scheduler;

using dungeons.utils.EntityUtil;
using dungeons.utils.ArrayUtil;

class RenderSystem extends System
{
    private var map:MapGrid;

    private var nodeList:NodeList<RenderNode>;
    private var positionListeners:Map<RenderNode, PositionChangeListener>;
    private var sceneEntities:Map<Renderable, RenderableEntity>;
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
    private var scheduler:Scheduler;

    public function new(scene:Scene, map:MapGrid, dungeon:Dungeon, assetFactory:AssetFactory, renderSignals:RenderSignals, scheduler:Scheduler)
    {
        super();
        this.scene = scene;
        this.map = map;
        this.assetFactory = assetFactory;
        this.scheduler = scheduler;
        renderSignals.hpChange.add(onHPChangeSignal);
        renderSignals.miss.add(onMissSignal);

        scene.addGraphic(renderDungeon(dungeon), RenderLayers.DUNGEON);
    }

    override public function addToEngine(engine:Engine):Void
    {
        positionListeners = new Map<RenderNode, PositionChangeListener>();

        sceneEntities = new Map<Renderable, RenderableEntity>();

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
        //        fovOverlayEntity.visible = false;

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
        var listener:PositionChangeListener = onNodePositionChanged.bind(node);
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

        if (value < 0)
        {
            addSlashAnimation(posX, posY);
        }
    }

    private function onMissSignal(posX:Int, posY:Int):Void
    {
        addFloatingText("Miss!", 0xFF0000, posX, posY);
    }

    private inline function addFloatingText(text:String, color:Int, posX:Int, posY:Int):Void
    {
        scene.create(FloatingText).init(assetFactory.tileSize, text, color, posX, posY);
    }

    private inline function addSlashAnimation(posX:Int, posY:Int):Void
    {
        scene.create(SlashAnimation).init(assetFactory, posX, posY, scheduler);
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

        var wallRow:Int = 2 + HXP.rand(5) * 2;
        var floorCol:Int = HXP.rand(15);
        var floorRow:Int = 0;
        var floorTileIndex:Int = tilesetCols * floorRow + floorCol;

        for (y in 0...dungeon.height)
        {
            for (x in 0...dungeon.width)
            {
                switch (dungeon.grid.get(x, y).tile)
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
        var targetX:Int = origX + ((HXP.random < 0.5) ? -1 : 1) * Std.int(tileSize * HXP.random * 0.5);
        var targetY:Int = origY - Std.int(tileSize * (0.5 + HXP.random * 0.5));

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

private class SlashAnimation extends com.haxepunk.Entity
{
    private var tween:NumTween;
    private var scheduler:Scheduler;

    public function new()
    {
        super();
        layer = RenderLayers.UI;
        tween = new NumTween();
    }

    public function init(assetFactory:AssetFactory, posX:Int, posY:Int, scheduler:Scheduler):Void
    {
        var image:Image = cast graphic;
        if (image == null)
            graphic = image = cast assetFactory.createTileImage("slash");

        var flip:Bool = HXP.random < 0.5;

        image.scaleX = flip ? -1 : 1;
        x = posX * assetFactory.tileSize;
        if (flip)
            x += image.width;
        y = posY * assetFactory.tileSize;

        this.scheduler = scheduler;
        scheduler.lock();

        tween.tween(1, 0, 0.25);
        tween.addEventListener(TweenEvent.FINISH, onTweenComplete);
        addTween(tween);
    }

    private function onTweenComplete(event:TweenEvent):Void
    {
        scheduler.unlock();
        scheduler = null;
        tween.removeEventListener(TweenEvent.FINISH, onTweenComplete);
        removeTween(tween);
        scene.recycle(this);
    }

    override public function update():Void
    {
        if (tween.active)
            cast(graphic, Image).alpha = tween.value;
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

private class PlayerInventory extends Panel
{
    private static inline var PADDING:Int = 4;

    private var inventory:Inventory;
    private var title:Label;
    private var items:Array<Label>;

    public function new(inventory:Inventory)
    {
        super();
        followCamera = true;

        title = new Label("Inventory", PADDING, PADDING);
        title.color = 0x0000FF;
        addControl(title);

        items = [];

        this.inventory = inventory;
        inventory.updated.add(redraw);
        redraw();
    }

    private function redraw():Void
    {
        if (inventory.items.length > 0)
        {
            for (item in items)
                removeControl(item);
            items = [];

            var w:Int = title.width + PADDING * 2;
            var y:Float = title.localY + title.height;

            for (entity in inventory.items)
            {
                var name:String = entity.getName();
                var item:Item = entity.get(Item);
                var s:String = name;
                if (item.quantity > 1)
                    s += " x" + item.quantity;
                var itemLabel:Label = new Label(s, 0, y);
                itemLabel.localX = PADDING;
                itemLabel.localY = y;

                if (itemLabel.width + PADDING * 2 > w)
                    w = itemLabel.width + PADDING * 2;

                y += itemLabel.height;

                items.push(itemLabel);
                addControl(itemLabel);
            }

            width = w;
            height = Std.int(y) + PADDING;

            localX = HXP.width - width;

            show();
        }
        else
        {
            hide();
        }
    }
}