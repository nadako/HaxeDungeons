package dungeons.systems;

import nme.geom.Rectangle;
import nme.display.BitmapData;
import nme.Lib;

import com.bit101.components.List;

import com.haxepunk.tweens.misc.NumTween;
import com.haxepunk.graphics.Canvas;
import com.haxepunk.graphics.Image;
import com.haxepunk.HXP;
import com.haxepunk.Graphic;
import com.haxepunk.World;

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
import dungeons.nodes.PlayerInventoryNode;
import dungeons.utils.Grid;

using dungeons.utils.EntityUtil;

// TODO: hide non-"memorable" entities that are not in FOV
class RenderSystem extends System
{
    private var width:Int;
    private var height:Int;

    private var nodeList:NodeList<RenderNode>;
    private var positionListeners:ObjectMap<RenderNode, PositionChangeListener>;
    private var worldEntities:ObjectMap<RenderNode, com.haxepunk.Entity>;
    private var world:World;

    private var fovSystem:FOVSystem;
    private var fovOverlayData:BitmapData;
    private var fovOverlayImage:Image;
    private var fovOverlayEntity:com.haxepunk.Entity;
    private var fovOverlayDirty:Bool;

    private var playerInventory:Inventory;
    private var playerInventoryMenu:List;

    public function new(world:World, width:Int, height:Int)
    {
        super();
        this.world = world;
        this.width = width;
        this.height = height;
    }

    override public function addToEngine(engine:Engine):Void
    {
        positionListeners = new ObjectMap();

        worldEntities = new ObjectMap();

        nodeList = engine.getNodeList(RenderNode);
        for (node in nodeList)
            onNodeAdded(node);
        nodeList.nodeAdded.add(onNodeAdded);
        nodeList.nodeRemoved.add(onNodeRemoved);

        fovSystem = engine.getSystem(FOVSystem);
        fovSystem.updated.add(onFOVUpdated);

        fovOverlayData = new BitmapData(width, height, true, 0xFF000000);

        fovOverlayImage = new Image(fovOverlayData);
        fovOverlayImage.scale = Constants.TILE_SIZE;
        fovOverlayEntity = world.addGraphic(fovOverlayImage, RenderLayers.FOV);

        fovOverlayDirty = true;

        playerInventoryMenu = new List(Lib.current);
        playerInventoryMenu.autoHideScrollBar = true;
        playerInventoryMenu.x = HXP.width - playerInventoryMenu.width;
        playerInventory = engine.getNodeList(PlayerInventoryNode).head.inventory;
        playerInventory.updated.add(redrawPlayerInventory);
        redrawPlayerInventory();
    }

    private function redrawPlayerInventory():Void
    {
        if (playerInventory.items.length == 0)
        {
            playerInventoryMenu.visible = false;
            return;
        }

        playerInventoryMenu.visible = true;

        playerInventoryMenu.removeAll();

        for (itemEntity in playerInventory.items)
        {
            var label:String = itemEntity.getName();
            var item:Item = itemEntity.get(Item);
            if (item.quantity > 1)
                label += " x" + item.quantity;
            playerInventoryMenu.addItem(label);
        }
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        fovSystem.updated.remove(onFOVUpdated);
        world.remove(fovOverlayEntity);

        nodeList.nodeAdded.remove(onNodeAdded);
        nodeList.nodeRemoved.remove(onNodeRemoved);
        nodeList = null;

        for (node in worldEntities.keys())
            world.remove(worldEntities.get(node));
        worldEntities = null;

        for (node in positionListeners.keys())
            node.position.changed.remove(positionListeners.get(node));
        positionListeners = null;

        playerInventory.updated.remove(redrawPlayerInventory);
        playerInventory = null;
    }

    private function onFOVUpdated():Void
    {
        fovOverlayDirty = true;
    }

    private function redrawFOVOverlay():Void
    {
        fovOverlayData.lock();
        var lightMap:Grid<Float> = fovSystem.lightMap;
        for (y in 0...lightMap.height)
        {
            for (x in 0...lightMap.width)
            {
                var intensity:Float = 0;

                var light:Float = lightMap.get(x, y);
                if (light > 0)
                    intensity = 0.3 + 0.7 * light;
                else if (fovSystem.inMemory(x, y))
                    intensity = 0.3;

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

        var entity:com.haxepunk.Entity = world.addGraphic(node.renderable.graphic, node.renderable.layer);
        worldEntities.set(node, entity);

        // TODO: hackity hack. refactor this to the health manager
        var health:Health = node.entity.get(Health);
        if (health != null)
            entity.addGraphic(new HealthBar(Constants.TILE_SIZE, health));

        entity.x = node.position.x * Constants.TILE_SIZE;
        entity.y = node.position.y * Constants.TILE_SIZE;
    }

    private function onNodeRemoved(node:RenderNode):Void
    {
        var listener:PositionChangeListener = positionListeners.get(node);
        node.position.changed.remove(listener);

        world.remove(worldEntities.get(node));
        worldEntities.remove(node);
    }

    private function onNodePositionChanged(node:RenderNode, oldX:Int, oldY:Int):Void
    {
        var entity:com.haxepunk.Entity = worldEntities.get(node);
        entity.x = node.position.x * Constants.TILE_SIZE;
        entity.y = node.position.y * Constants.TILE_SIZE;
    }

    override public function update(time:Float):Void
    {
        if (fovOverlayDirty)
            redrawFOVOverlay();
    }
}

class RenderLayers
{
    public static inline var DUNGEON:Int = HXP.BASELAYER;
    public static inline var OBJECT:Int = HXP.BASELAYER - 1;
    public static inline var CHARACTER:Int = HXP.BASELAYER - 2;
    public static inline var FOV:Int = HXP.BASELAYER - 3;
    public static inline var UI:Int = HXP.BASELAYER - 4;
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
        HXP.world.addTween(tween);

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
        HXP.world.removeTween(tween);

        health.updated.remove(onHealthUpdate);
        health = null;
    }
}
