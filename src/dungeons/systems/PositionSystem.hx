package dungeons.systems;

import dungeons.systems.RenderSystem;
import nme.ObjectHash;
import dungeons.components.Position;
import de.polygonal.ds.Array2;

import net.richardlord.ash.core.Entity;
import net.richardlord.ash.core.Game;
import net.richardlord.ash.tools.ListIteratingSystem;

import dungeons.nodes.PositionNode;

class PositionSystem extends ListIteratingSystem<PositionNode>
{
    private var positionGrid:Array2<Array<Entity>>;
    private var nodeListeners:ObjectHash<PositionNode, PositionChangeListener>;

    private var emptyIterable:Iterable<Entity>;
    private var width:Int;
    private var height:Int;

    public function new(width:Int, height:Int)
    {
        this.width = width;
        this.height = height;

        emptyIterable = {
            iterator: function() {
                return {
                    hasNext: function() {return false;},
                    next: function() {return null;}
                };
            }
        };
        super(PositionNode, null, nodeAdded, nodeRemoved);
    }

    public function getEntitiesAt(x:Int, y:Int):Iterable<Entity>
    {
        var entities = positionGrid.get(x, y);
        if (entities == null)
            return emptyIterable;
        else
            return entities;
    }

    override public function addToGame(game:Game):Void
    {
        positionGrid = new Array2(width, height);
        nodeListeners = new ObjectHash();
        super.addToGame(game);
    }

    override public function removeFromGame(game:Game):Void
    {
        super.removeFromGame(game);
        positionGrid = null;
        for (listener in nodeListeners)
            listener.dispose();
        nodeListeners = null;
    }

    private function nodeAdded(node:PositionNode):Void
    {
        var entities = positionGrid.get(node.position.x, node.position.y);
        if (entities == null)
        {
            entities = [node.entity];
            positionGrid.set(node.position.x, node.position.y, entities);
        }
        else
        {
            entities.push(node.entity);
        }
//        trace("Added node to " + node.position.x + "x" + node.position.y);
        nodeListeners.set(node, new PositionChangeListener(node, positionGrid));
    }

    private function nodeRemoved(node:PositionNode):Void
    {
        var listener = nodeListeners.get(node);
        nodeListeners.remove(node);
        listener.dispose();

        var entities = positionGrid.get(node.position.x, node.position.y);
//        trace("Removed node from " + node.position.x + "x" + node.position.y);
        entities.remove(node.entity);
    }

    override public function update(time:Float):Void
    {
    }
}

private class PositionChangeListener
{
    public var node(default, null):PositionNode;

    private var grid:Array2<Array<Entity>>;
    private var previousPosition:Position;

    public function new(node:PositionNode, grid:Array2<Array<Entity>>):Void
    {
        this.node = node;
        this.grid = grid;
        previousPosition = new Position(node.position.x, node.position.y);
        node.position.changed.add(onPositionChange);
    }

    private function onPositionChange():Void
    {
        var oldEntities = grid.get(previousPosition.x, previousPosition.y);
        oldEntities.remove(node.entity);

        var newEntities = grid.get(node.position.x, node.position.y);
        if (newEntities == null)
        {
            newEntities = [node.entity];
            grid.set(node.position.x, node.position.y, newEntities);
        }
        else
        {
            newEntities.push(node.entity);
        }

//        trace("Moved node from " + previousPosition.x + "x" + previousPosition.y + " to " + node.position.x + "x" + node.position.y);

        previousPosition.moveTo(node.position.x, node.position.y);
    }

    public function dispose():Void
    {
        previousPosition = null;
        node.position.changed.remove(onPositionChange);
        node = null;
    }
}