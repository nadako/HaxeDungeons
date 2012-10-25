package dungeons.systems;

import nme.geom.Point;
import nme.display.DisplayObject;

import com.eclecticdesignstudio.motion.Actuate;

import net.richardlord.ash.core.Game;
import net.richardlord.ash.tools.ListIteratingSystem;

import dungeons.nodes.CameraFocusNode;

class CameraSystem extends ListIteratingSystem<CameraFocusNode>
{
    private var scene:DisplayObject;
    private var animateDuration:Float;
    private var focus:CameraFocusNode;

    public function new(scene:DisplayObject, animateDuration:Float = 0.5)
    {
        super(CameraFocusNode, null, nodeAdded, nodeRemoved);
        this.scene = scene;
        this.animateDuration = animateDuration;
    }

    override public function removeFromGame(game:Game):Void
    {
        super.removeFromGame(game);
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
        scene.x = coords.x;
        scene.y = coords.y;
    }

    private function getSceneCoords():Point
    {
        var TILE_SIZE = 8;
        var x = scene.stage.stageWidth / 2 - focus.position.x * TILE_SIZE * scene.scaleX;
        var y = scene.stage.stageHeight / 2 - focus.position.y * TILE_SIZE * scene.scaleY;
        return new Point(x, y);
    }

    private function nodeRemoved(node:CameraFocusNode):Void
    {
        node.position.changed.remove(onFocusMove);
    }

    private function onFocusMove():Void
    {
        var coords = getSceneCoords();
        Actuate.stop(scene);
        Actuate.tween(scene, animateDuration, {x: coords.x, y: coords.y});
    }

    override public function update(time:Float):Void
    {
    }
}
