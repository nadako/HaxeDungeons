package dungeons.systems;

import nme.display.DisplayObject;

import net.richardlord.ash.tools.ListIteratingSystem;

import dungeons.nodes.CameraFocusNode;

class CameraSystem extends ListIteratingSystem<CameraFocusNode>
{
    private var scene:DisplayObject;

    public function new(scene:DisplayObject)
    {
        super(CameraFocusNode, nodeUpdate);
        this.scene = scene;
    }

    private function nodeUpdate(node:CameraFocusNode, dt:Float):Void
    {
        var TILE_SIZE:Int = 8;
        scene.x = scene.stage.stageWidth / 2 - node.position.x * TILE_SIZE * scene.scaleX;
        scene.y = scene.stage.stageHeight / 2 - node.position.y * TILE_SIZE * scene.scaleY;
    }
}
