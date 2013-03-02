package dungeons.systems;

import nme.display.BitmapData;

import com.haxepunk.graphics.Image;

import ash.ObjectHash;
import ash.core.NodeList;
import ash.core.Engine;
import ash.core.System;

import dungeons.nodes.FOVNode;
import dungeons.nodes.LightOccluderNode;
import dungeons.components.Position;
import dungeons.utils.ShadowCaster;
import dungeons.utils.Grid;

// TODO: hide non-memorable stuff when not lit
class FOVSystem extends System, implements IShadowCasterDataProvider
{
    private var overlayData:BitmapData;
    private var overlayDirty:Bool;
    public var overlayImage(default, null):Image;

    private var calculationDisabled:Bool;
    private var shadowCaster:ShadowCaster;

    private var lightMap:Grid<Float>;
    private var memoryMap:Grid<Bool>;

    private var occluders:NodeList<LightOccluderNode>;
    private var occluderListeners:ObjectHash<LightOccluderNode, PositionChangeListener>;
    private var occludeMap:Grid<Int>;

    private var fovCaster:FOVNode;

    public function new(width:Int, height:Int)
    {
        super();
        overlayData = new BitmapData(width, height, true, 0);
        overlayImage = new Image(overlayData);
        overlayDirty = false;
        calculationDisabled = false;
        shadowCaster = new ShadowCaster(this);
        lightMap = new Grid(width, height);
        occludeMap = new Grid(width, height);
        memoryMap = new Grid(width, height);
    }

    override public function addToEngine(engine:Engine):Void
    {
        occluderListeners = new ObjectHash();

        calculationDisabled = true;

        occluders = engine.getNodeList(LightOccluderNode);
        for (node in occluders)
            occluderNodeAdded(node);
        occluders.nodeAdded.add(occluderNodeAdded);
        occluders.nodeRemoved.add(occluderNodeRemoved);

        var fovCasters = engine.getNodeList(FOVNode);
        for (node in fovCasters)
            onFOVAdded(node);
        fovCasters.nodeAdded.add(onFOVAdded);
        fovCasters.nodeRemoved.add(onFOVRemoved);

        calculationDisabled = false;
        calculateLightMap();
        redrawOverlay();
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        lightMap.clear();
        memoryMap.clear();

        for (node in occluderListeners.keys())
            node.position.changed.remove(occluderListeners.get(node));
        occluderListeners = null;
        occludeMap.clear();

        var fovCasters = engine.getNodeList(FOVNode);
        fovCasters.nodeAdded.remove(onFOVAdded);
        fovCasters.nodeRemoved.remove(onFOVRemoved);
        fovCaster = null;
    }

    private function occluderNodeAdded(node:LightOccluderNode):Void
    {
        addOccluder(node.position.x, node.position.y);

        var listener = callback(onOccluderPositionChange, node);
        node.position.changed.add(listener);
        occluderListeners.set(node, listener);

        if (isInFOV(node.position.x, node.position.y))
            calculateLightMap();
    }

    private function onOccluderPositionChange(node:LightOccluderNode, oldX:Int, oldY:Int):Void
    {
        removeOccluder(oldX, oldY);
        addOccluder(node.position.x, node.position.y);

        if (isInFOV(oldX, oldY) || isInFOV(node.position.x, node.position.y))
            calculateLightMap();
    }

    private function occluderNodeRemoved(node:LightOccluderNode):Void
    {
        removeOccluder(node.position.x, node.position.y);
        var listener = occluderListeners.get(node);
        occluderListeners.remove(node);
        node.position.changed.remove(listener);

        if (isInFOV(node.position.x, node.position.y))
            calculateLightMap();
    }

    private inline function addOccluder(x:Int, y:Int):Void
    {
        occludeMap.set(x, y, occludeMap.get(x, y) + 1);
    }

    private inline function removeOccluder(x:Int, y:Int):Void
    {
        occludeMap.set(x, y, occludeMap.get(x, y) - 1);
    }

    public function isBlocking(x:Int, y:Int):Bool
    {
        return occludeMap.get(x, y) > 0;
    }

    public function light(x:Int, y:Int, intensity:Float):Void
    {
        lightMap.set(x, y, intensity);
        memoryMap.set(x, y, true);
    }

    private inline function isInFOV(x:Int, y:Int):Bool
    {
        return lightMap.get(x, y) > 0;
    }

    public inline function inMemory(x:Int, y:Int):Bool
    {
        return memoryMap.get(x, y);
    }

    private function calculateLightMap():Void
    {
        // we disable recalculation on initialization and then call it for all added objects
        if (calculationDisabled)
            return;

        lightMap.clear();

        if (fovCaster != null)
            shadowCaster.calculateLight(fovCaster.position.x, fovCaster.position.y, fovCaster.fov.radius);

        overlayDirty = true;
    }

    private function redrawOverlay():Void
    {
        overlayData.lock();
        for (y in 0...lightMap.height)
        {
            for (x in 0...lightMap.width)
            {
                var intensity:Float = 0;

                var light:Float = lightMap.get(x, y);
                if (light > 0)
                    intensity = 0.3 + 0.7 * light;
                else if (memoryMap.get(x, y))
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

                overlayData.setPixel32(x, y, color);
            }
        }
        overlayData.unlock();
        overlayImage.updateBuffer();
        overlayDirty = false;
    }

    private function onFOVAdded(node:FOVNode):Void
    {
        if (fovCaster != null)
            onFOVRemoved(fovCaster);

        fovCaster = node;
        node.position.changed.add(onFOVMove);

        calculateLightMap();
    }

    private function onFOVMove(oldX:Int, oldY:Int):Void
    {
        calculateLightMap();
    }

    private function onFOVRemoved(node:FOVNode):Void
    {
        node.position.changed.remove(onFOVMove);
        if (node == fovCaster)
            fovCaster = null;

        calculateLightMap();
    }

    override public function update(time:Float):Void
    {
        if (overlayDirty)
            redrawOverlay();
    }
}
