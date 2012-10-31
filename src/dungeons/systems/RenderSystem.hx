package dungeons.systems;

import nme.ObjectHash;
import nme.display.DisplayObjectContainer;
import nme.display.Tilesheet;

import com.eclecticdesignstudio.motion.Actuate;

import net.richardlord.ash.core.Game;
import net.richardlord.ash.tools.ListIteratingSystem;

import dungeons.nodes.RenderNode;

class RenderSystem extends ListIteratingSystem<RenderNode>
{
    private var container:DisplayObjectContainer;
    private var moveListeners:ObjectHash<RenderNode, PositionChangeListener>;

    public function new(container:DisplayObjectContainer)
    {
        this.container = container;
        super(RenderNode, null, nodeAdded, nodeRemoved);
    }

    override public function addToGame(game:Game):Void
    {
        moveListeners = new ObjectHash<RenderNode, PositionChangeListener>();
        super.addToGame(game);
    }

    override public function removeFromGame(game:Game):Void
    {
        super.removeFromGame(game);
        for (listener in moveListeners)
            listener.dispose();
        moveListeners = null;
    }

    private function nodeAdded(node:RenderNode):Void
    {
        container.addChild(node.renderable.displayObject);
        node.renderable.displayObject.x = node.position.x * Constants.TILE_SIZE;
        node.renderable.displayObject.y = node.position.y * Constants.TILE_SIZE;
        moveListeners.set(node, new PositionChangeListener(node));
    }

    private function nodeRemoved(node:RenderNode):Void
    {
        container.removeChild(node.renderable.displayObject);
        var listener = moveListeners.get(node);
        listener.dispose();
        moveListeners.remove(node);
    }

    override public function update(time:Float):Void
    {
    }
}

private class PositionChangeListener
{
    private static inline var ANIM_DURATION:Float = 0.25;

    private var node:RenderNode;

    public function new(node:RenderNode):Void
    {
        this.node = node;
        node.position.changed.add(onPositionChange);
    }

    private function onPositionChange():Void
    {
        var x = node.position.x * Constants.TILE_SIZE;
        var y = node.position.y * Constants.TILE_SIZE;
        Actuate.stop(node.renderable.displayObject);
        Actuate.tween(node.renderable.displayObject, ANIM_DURATION, {x: x, y: y});
    }

    public function dispose():Void
    {
        node.position.changed.remove(onPositionChange);
        Actuate.stop(node.renderable.displayObject);
    }
}