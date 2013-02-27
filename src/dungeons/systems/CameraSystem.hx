package dungeons.systems;

import nme.geom.Rectangle;
import nme.geom.Point;
import nme.display.DisplayObject;

import com.eclecticdesignstudio.motion.Actuate;

import ash.core.Engine;
import ash.tools.ListIteratingSystem;

import dungeons.nodes.CameraFocusNode;

class CameraSystem extends ListIteratingSystem<CameraFocusNode>
{
    private var viewport:Rectangle;
    private var animateDuration:Float;
    private var focus:CameraFocusNode;

    public function new(viewport:Rectangle, animateDuration:Float = 0.5)
    {
        super(CameraFocusNode, null, nodeAdded, nodeRemoved);
        this.viewport = viewport;
        this.animateDuration = animateDuration;
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        super.removeFromEngine(engine);
        if (focus != null)
            nodeRemoved(focus);
    }

    private function nodeAdded(node:CameraFocusNode):Void
    {
        if (focus != null)
            nodeRemoved(focus);

        focus = node;
        focus.position.changed.add(onFocusMove);

        var coords = getSceneCoords();
        viewport.x = coords.x;
        viewport.y = coords.y;
    }

    private function getSceneCoords():Point
    {
        var x = Math.max(0, focus.position.x * Constants.TILE_SIZE - viewport.width / 2);
        var y = Math.max(0, focus.position.y * Constants.TILE_SIZE - viewport.height / 2);
        return new Point(x, y);
    }

    private function nodeRemoved(node:CameraFocusNode):Void
    {
        node.position.changed.remove(onFocusMove);
    }

    private function onFocusMove(oldX:Int, oldY:Int):Void
    {
        var coords = getSceneCoords();
//        viewport.x = coords.x;
//        viewport.y = coords.y;
        Actuate.stop(viewport);
        Actuate.tween(viewport, animateDuration, {x: coords.x, y: coords.y});
    }
}
