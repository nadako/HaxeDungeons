package dungeons.systems;

import com.haxepunk.HXP;
import com.haxepunk.Graphic;
import com.haxepunk.World;

import ash.ObjectHash;
import ash.core.Engine;
import ash.core.NodeList;
import ash.core.System;

import dungeons.nodes.RenderNode;
import dungeons.components.Position.PositionChangeListener;

class RenderSystem extends System
{
    private var nodeList:NodeList<RenderNode>;
    private var positionListeners:ObjectHash<RenderNode, PositionChangeListener>;
    private var worldEntities:ObjectHash<RenderNode, com.haxepunk.Entity>;
    private var world:World;

    public function new(world:World)
    {
        super();
        this.world = world;
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
    }

    override public function removeFromEngine(engine:Engine):Void
    {
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

    private function onNodeAdded(node:RenderNode):Void
    {
        var listener:PositionChangeListener = callback(onNodePositionChanged, node);
        node.position.changed.add(listener);
        positionListeners.set(node, listener);

        var entity:com.haxepunk.Entity = world.addGraphic(node.renderable.graphic, node.renderable.layer);
        worldEntities.set(node, entity);

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
}

class RenderLayers
{
    public static inline var DUNGEON:Int = HXP.BASELAYER;
    public static inline var OBJECT:Int = HXP.BASELAYER - 1;
    public static inline var CHARACTER:Int = HXP.BASELAYER - 2;
}
