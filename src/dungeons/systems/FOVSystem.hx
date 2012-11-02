package dungeons.systems;

import nme.ObjectHash;

import net.richardlord.ash.core.NodeList;
import net.richardlord.ash.core.Game;
import net.richardlord.ash.core.System;

import dungeons.nodes.FOVNode;
import dungeons.nodes.LightOccluderNode;
import dungeons.components.Position;
import dungeons.ShadowCaster;

class FOVSystem extends System, implements IShadowCasterDataProvider
{
    private var width:Int;
    private var height:Int;
    private var shadowCaster:ShadowCaster;

    private var lightMap:IntHash<Float>;

    private var occluders:NodeList<LightOccluderNode>;
    private var occluderListeners:ObjectHash<LightOccluderNode, PositionChangeListener>;
    private var occludeMap:IntHash<Int>;

    private var fovCaster:FOVNode;

    public function new(width:Int, height:Int)
    {
        this.width = width;
        this.height = height;
        shadowCaster = new ShadowCaster(this);
        lightMap = new IntHash();
    }

    override public function addToGame(game:Game):Void
    {
        occludeMap = new IntHash();
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
        for (node in occluderListeners.keys())
            node.position.changed.remove(occluderListeners.get(node));
        occluderListeners = null;
        occludeMap = null;

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

    private inline function getKey(x:Int, y:Int):Int
    {
        return y * width + x;
    }

    private function addOccluder(x:Int, y:Int):Void
    {
        var key:Int = getKey(x, y);
        var value:Int = occludeMap.get(key);
        occludeMap.set(key, value + 1);
    }

    private function removeOccluder(x:Int, y:Int):Void
    {
        var key:Int = getKey(x, y);
        var value:Int = occludeMap.get(key);
        occludeMap.set(key, Std.int(Math.max(0, value - 1)));
    }

    public function isBlocking(x:Int, y:Int):Bool
    {
        if (x < 0 || x >= width || y < 0 || y >= height)
            return true;

        return occludeMap.get(getKey(x, y)) > 0;
    }

    public function light(x:Int, y:Int, intensity:Float):Void
    {
        lightMap.set(getKey(x, y), intensity);
    }

    public function getLight(x:Int, y:Int):Float
    {
        var key:Int = getKey(x, y);
        if (lightMap.exists(key))
            return lightMap.get(key);
        else
            return 0;
    }

    private function calculateLightMap():Void
    {
        lightMap = new IntHash();

        if (fovCaster == null)
            return;

        lightMap.set(getKey(fovCaster.position.x, fovCaster.position.y), 1);
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
