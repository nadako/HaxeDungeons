package dungeons.systems;

import com.haxepunk.HXP;
import com.haxepunk.tweens.motion.LinearMotion;

import ash.core.Engine;
import ash.tools.ListIteratingSystem;

import dungeons.nodes.CameraFocusNode;

class CameraSystem extends ListIteratingSystem<CameraFocusNode>
{
    private var focus:CameraFocusNode;
    private var cameraMotion:LinearMotion;

    public function new()
    {
        super(CameraFocusNode, null, nodeAdded, nodeRemoved);
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        super.removeFromEngine(engine);
        if (focus != null)
            nodeRemoved(focus);
        if (cameraMotion != null)
            HXP.scene.removeTween(cameraMotion);
    }

    private function nodeAdded(node:CameraFocusNode):Void
    {
        if (focus != null)
            nodeRemoved(focus);

        focus = node;
        focus.position.changed.add(onFocusMove);

        HXP.camera.x = focus.position.x * Constants.TILE_SIZE - HXP.halfWidth;
        HXP.camera.y = focus.position.y * Constants.TILE_SIZE - HXP.halfHeight;
    }

    private function nodeRemoved(node:CameraFocusNode):Void
    {
        node.position.changed.remove(onFocusMove);
    }

    private function onFocusMove(oldX:Int, oldY:Int):Void
    {
        if (cameraMotion == null)
        {
            cameraMotion = new LinearMotion();
            HXP.scene.addTween(cameraMotion);
        }
        cameraMotion.setMotion(HXP.camera.x, HXP.camera.y, focus.position.x * Constants.TILE_SIZE - HXP.halfWidth, focus.position.y * Constants.TILE_SIZE - HXP.halfHeight, 0.25);
    }

    override public function update(dt:Float):Void
    {
        if (cameraMotion != null && cameraMotion.active)
        {
            HXP.camera.x = Math.round(cameraMotion.x);
            HXP.camera.y = Math.round(cameraMotion.y);
        }
    }
}
