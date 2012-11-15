package dungeons.systems;

import nme.ObjectHash;

import net.richardlord.ash.core.NodeList;
import net.richardlord.ash.core.Game;
import net.richardlord.ash.core.System;

import dungeons.PositionMap;
import dungeons.nodes.FOVNode;
import dungeons.nodes.LightOccluderNode;
import dungeons.components.Position;
import dungeons.ShadowCaster;

class FOVSystem extends System, implements IShadowCasterDataProvider
{
    private var shadowCaster:ShadowCaster;

    private var lightMap:PositionMap<Float>;
    private var memoryMap:PositionMap<Bool>;

    private var occluders:NodeList<LightOccluderNode>;
    private var occluderListeners:ObjectHash<LightOccluderNode, PositionChangeListener>;
    private var occludeMap:PositionMap<Int>;

    private var fovCaster:FOVNode;

    public function new(width:Int, height:Int)
    {
        super();
        shadowCaster = new ShadowCaster(this);
        lightMap = new PositionMap(width, height);
        occludeMap = new PositionMap(width, height);
        memoryMap = new PositionMap(width, height);
    }

    override public function addToGame(game:Game):Void
    {
        occluderListeners = new ObjectHash();

        occluders = game.getNodeList(LightOccluderNode);
        for (node in occluders)
            occluderNodeAdded(node);
        occluders.nodeAdded.add(occluderNodeAdded);
        occluders.nodeRemoved.add(occluderNodeRemoved);

        var fovCasters = game.getNodeList(FOVNode);
        for (node in fovCasters)
            onFOVAdded(node);
        fovCasters.nodeAdded.add(onFOVAdded);
        fovCasters.nodeRemoved.add(onFOVRemoved);
    }

    override public function removeFromGame(game:Game):Void
    {
        lightMap.clear();
        memoryMap.clear();

        for (node in occluderListeners.keys())
            node.position.changed.remove(occluderListeners.get(node));
        occluderListeners = null;
        occludeMap.clear();

        var fovCasters = game.getNodeList(FOVNode);
        fovCasters.nodeAdded.remove(onFOVAdded);
        fovCasters.nodeRemoved.remove(onFOVRemoved);
        fovCaster = null;
    }

    override public function update(time:Float):Void
    {
    }

    private function occluderNodeAdded(node:LightOccluderNode):Void
    {
        addOccluder(node.position.x, node.position.y);

        var listener = callback(onOccluderPositionChange, node);
        node.position.changed.add(listener);
        occluderListeners.set(node, listener);

        calculateLightMap();
    }

    private function onOccluderPositionChange(node:LightOccluderNode, oldX:Int, oldY:Int):Void
    {
        removeOccluder(oldX, oldY);
        addOccluder(node.position.x, node.position.y);

        calculateLightMap();
    }

    private function occluderNodeRemoved(node:LightOccluderNode):Void
    {
        removeOccluder(node.position.x, node.position.y);
        var listener = occluderListeners.get(node);
        occluderListeners.remove(node);
        node.position.changed.remove(listener);

        calculateLightMap();
    }

    private function addOccluder(x:Int, y:Int):Void
    {
        occludeMap.set(x, y, occludeMap.get(x, y) + 1);
    }

    private function removeOccluder(x:Int, y:Int):Void
    {
        var value:Int = occludeMap.get(x, y);
        occludeMap.set(x, y, Std.int(Math.max(0, value - 1)));
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

    public function getLight(x:Int, y:Int):Float
    {
        var value:Float = lightMap.get(x, y);
        if (Math.isNaN(value))
            return 0;
        else
            return value;
    }

    public function inMemory(x:Int, y:Int):Bool
    {
        return memoryMap.get(x, y);
    }

    private function calculateLightMap():Void
    {
        lightMap.clear();

        if (fovCaster == null)
            return;

        light(fovCaster.position.x, fovCaster.position.y, 1);
        shadowCaster.calculateLight(fovCaster.position.x, fovCaster.position.y, fovCaster.fov.radius);
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
