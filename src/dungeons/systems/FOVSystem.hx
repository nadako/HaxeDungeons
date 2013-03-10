package dungeons.systems;

import dungeons.utils.Map;
import nme.display.BitmapData;

import com.haxepunk.graphics.Image;

import ash.ObjectMap;
import ash.core.NodeList;
import ash.core.Engine;
import ash.core.System;
import ash.signals.Signal0;

import dungeons.nodes.FOVNode;
import dungeons.nodes.LightOccluderNode;
import dungeons.components.Position;
import dungeons.utils.ShadowCaster;
import dungeons.utils.Grid;

class FOVSystem extends System
{
    private var calculationDisabled:Bool;
    private var shadowCaster:ShadowCaster;

    private var map:Map;
    
    public var lightMap(default, null):Grid<Float>;
    
    private var occluders:NodeList<LightOccluderNode>;
    private var occluderListeners:ObjectMap<LightOccluderNode, PositionChangeListener>;
    
    private var fovCaster:FOVNode;

    public var updated(default, null):Signal0;

    public function new(map:Map)
    {
        super();
        this.map = map;
        lightMap = new Grid(map.width, map.height);
        shadowCaster = new ShadowCaster(light, isOccluded);
        updated = new Signal0();
    }

    override public function addToEngine(engine:Engine):Void
    {
        occluderListeners = new ObjectMap();

        calculationDisabled = true;

        occluders = engine.getNodeList(LightOccluderNode);
        for (node in occluders)
            occluderNodeAdded(node);
        occluders.nodeAdded.add(occluderNodeAdded);
        occluders.nodeRemoved.add(occluderNodeRemoved);

        var fovCasters:NodeList<FOVNode> = engine.getNodeList(FOVNode);
        for (node in fovCasters)
            onFOVAdded(node);
        fovCasters.nodeAdded.add(onFOVAdded);
        fovCasters.nodeRemoved.add(onFOVRemoved);

        calculationDisabled = false;
        calculateLightMap();
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        lightMap.clear();

        for (node in occluderListeners.keys())
            node.position.changed.remove(occluderListeners.get(node));
        occluderListeners = null;

        var fovCasters:NodeList<FOVNode> = engine.getNodeList(FOVNode);
        fovCasters.nodeAdded.remove(onFOVAdded);
        fovCasters.nodeRemoved.remove(onFOVRemoved);
        fovCaster = null;
    }

    private function occluderNodeAdded(node:LightOccluderNode):Void
    {
        map.get(node.position.x, node.position.y).numOccluders++;

        var listener = callback(onOccluderPositionChange, node);
        node.position.changed.add(listener);
        occluderListeners.set(node, listener);

        if (isInFOV(node.position.x, node.position.y))
            calculateLightMap();
    }

    private function onOccluderPositionChange(node:LightOccluderNode, oldX:Int, oldY:Int):Void
    {
        map.get(oldX, oldY).numOccluders--;
        map.get(node.position.x, node.position.y).numOccluders++;

        if (isInFOV(oldX, oldY) || isInFOV(node.position.x, node.position.y))
            calculateLightMap();
    }

    private function occluderNodeRemoved(node:LightOccluderNode):Void
    {
        map.get(node.position.x, node.position.y).numOccluders--;

        var listener = occluderListeners.get(node);
        occluderListeners.remove(node);
        node.position.changed.remove(listener);

        if (isInFOV(node.position.x, node.position.y))
            calculateLightMap();
    }


    // shadowcaster callback for marking cell as lit
    private function light(x:Int, y:Int, intensity:Float):Void
    {
        lightMap.set(x, y, intensity);
        map.get(x, y).inMemory = true;
    }

    private function isOccluded(x:Int, y:Int):Bool
    {
        return map.get(x, y).numOccluders > 0;
    }

    private inline function isInFOV(x:Int, y:Int):Bool
    {
        return lightMap.get(x, y) > 0;
    }

    public inline function inMemory(x:Int, y:Int):Bool
    {
        return map.get(x, y).inMemory;
    }

    private function calculateLightMap():Void
    {
        // we disable recalculation on initialization and then call it for all added objects
        if (calculationDisabled)
            return;

        lightMap.clear();

        if (fovCaster != null)
            shadowCaster.calculateLight(fovCaster.position.x, fovCaster.position.y, fovCaster.fov.radius);

        updated.dispatch();
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
}
