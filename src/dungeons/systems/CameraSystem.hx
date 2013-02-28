package dungeons.systems;

import com.haxepunk.tweens.misc.MultiVarTween;
import com.haxepunk.HXP;

import ash.core.Engine;
import ash.tools.ListIteratingSystem;

import dungeons.nodes.CameraFocusNode;

class CameraSystem extends ListIteratingSystem<CameraFocusNode>
{
    private var focus:CameraFocusNode;
    private var cameraTween:MultiVarTween;

    public function new()
    {
        super(CameraFocusNode, null, nodeAdded, nodeRemoved);
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

        HXP.camera.x = focus.position.x * Constants.TILE_SIZE - HXP.halfWidth / HXP.screen.scale;
        HXP.camera.y = focus.position.y * Constants.TILE_SIZE - HXP.halfHeight / HXP.screen.scale;
    }

    private function nodeRemoved(node:CameraFocusNode):Void
    {
        node.position.changed.remove(onFocusMove);
        if (cameraTween != null)
        {
            HXP.world.removeTween(cameraTween);
            cameraTween = null;
        }
    }

    private function onFocusMove(oldX:Int, oldY:Int):Void
    {
        if (cameraTween == null)
            cameraTween = cast HXP.world.addTween(new MultiVarTween());

        var x:Float = focus.position.x * Constants.TILE_SIZE - HXP.halfWidth / HXP.screen.scale;
        var y:Float = focus.position.y * Constants.TILE_SIZE - HXP.halfHeight / HXP.screen.scale;

        cameraTween.tween(HXP.camera, {x: x, y: y}, 0.25);
        cameraTween.start();
    }
}
