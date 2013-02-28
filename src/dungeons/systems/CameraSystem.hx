package dungeons.systems;

import com.haxepunk.HXP;

import ash.core.Engine;
import ash.tools.ListIteratingSystem;

import dungeons.nodes.CameraFocusNode;

class CameraSystem extends ListIteratingSystem<CameraFocusNode>
{
    private var focus:CameraFocusNode;

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

        onFocusMove(0, 0);
    }

    private function nodeRemoved(node:CameraFocusNode):Void
    {
        node.position.changed.remove(onFocusMove);
    }

    private function onFocusMove(oldX:Int, oldY:Int):Void
    {
        HXP.camera.x = focus.position.x * Constants.TILE_SIZE - HXP.halfWidth / HXP.screen.scale;
        HXP.camera.y = focus.position.y * Constants.TILE_SIZE - HXP.halfHeight / HXP.screen.scale;
    }
}
