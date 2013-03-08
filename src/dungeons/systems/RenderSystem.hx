package dungeons.systems;

import nme.geom.Rectangle;
import nme.display.BitmapData;

import com.haxepunk.graphics.Canvas;
import com.haxepunk.graphics.Image;
import com.haxepunk.HXP;
import com.haxepunk.Graphic;
import com.haxepunk.World;

import ash.ObjectHash;
import ash.core.Engine;
import ash.core.NodeList;
import ash.core.System;

import dungeons.nodes.RenderNode;
import dungeons.components.Position.PositionChangeListener;
import dungeons.components.Health;
import dungeons.components.Fighter;
import dungeons.utils.Grid;

// TODO: hide non-"memorable" entities that are not in FOV
class RenderSystem extends System
{
    private var width:Int;
    private var height:Int;

    private var nodeList:NodeList<RenderNode>;
    private var positionListeners:ObjectHash<RenderNode, PositionChangeListener>;
    private var worldEntities:ObjectHash<RenderNode, com.haxepunk.Entity>;
    private var world:World;

    private var fovSystem:FOVSystem;
    private var fovOverlayData:BitmapData;
    private var fovOverlayImage:Image;
    private var fovOverlayEntity:com.haxepunk.Entity;
    private var fovOverlayDirty:Bool;

    public function new(world:World, width:Int, height:Int)
    {
        super();
        this.world = world;
        this.width = width;
        this.height = height;
    }

    override public function addToEngine(engine:Engine):Void
    {
        positionListeners = new ObjectHash();

        worldEntities = new ObjectHash();

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
}

private class HealthBar extends Canvas
{
    private var health:Health;

    public function new(parentWidth:Int, health:Health)
    {
        var width:Int = Std.int(parentWidth * 1.5);

        super(width, 3);
        x = -(width - parentWidth) / 2;
        y = -4;
        alpha = 0.5;

        this.health = health;
        this.health.updated.add(updateHealth);
        updateHealth();
    }

    private function updateHealth():Void
    {
        var percent:Float = health.currentHP / health.maxHP;

        var rect:Rectangle = HXP.rect;
        rect.x = rect.y = 0;
        rect.width = width;
        rect.height = height;
        fill(rect);

        rect.x = rect.y = 1;
        rect.height = 1;
        rect.width = Std.int((width - 2) * percent);
        fill(rect, 0xFF0000);
    }

    public function dispose():Void
    {
        health.updated.remove(updateHealth);
        health = null;
    }
}
