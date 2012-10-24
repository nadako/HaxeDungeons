package systems;

import nme.display.Tilesheet;
import nme.display.Graphics;

import net.richardlord.ash.core.NodeList;
import net.richardlord.ash.core.Game;
import net.richardlord.ash.core.System;

import nodes.DungeonTileNode;

class DungeonRenderSystem extends System
{
    private var canvas:Graphics;
    private var tiles:Tilesheet;
    private var nodeList:NodeList<DungeonTileNode>;
    private var needUpdate:Bool;

    public function new(canvas:Graphics, tiles:Tilesheet)
    {
        this.canvas = canvas;
        this.tiles = tiles;
    }

    override public function addToGame(game:Game):Void
    {
        needUpdate = true;
        nodeList = game.getNodeList(DungeonTileNode);
        if (!nodeList.empty)
            markNeedUpdate();
        nodeList.nodeAdded.add(markNeedUpdate);
        nodeList.nodeRemoved.add(markNeedUpdate);
    }

    override public function removeFromGame(game:Game):Void
    {
        nodeList.nodeAdded.remove(markNeedUpdate);
        nodeList.nodeRemoved.remove(markNeedUpdate);
    }

    private function markNeedUpdate(node:DungeonTileNode = null):Void
    {
        needUpdate = true;
    }

    override public function update(time:Float):Void
    {
        if (needUpdate)
        {
            needUpdate = false;

            canvas.clear();
            var TILE_SIZE:Int = 8;
            var tileData:Array<Float> = new Array<Float>();
            for (node in nodeList)
            {
                var tileID:Float;
                switch (node.renderable.tile)
                {
                    case Wall:
                        tileID = 0;
//                        tileID = isVerticalWall(dungeon.grid, x, y) ? 1 : 0;
                    case Floor:
                        tileID = 2;
                    default:
                        continue;
                }
                tileData.push(node.position.x * TILE_SIZE);
                tileData.push(node.position.y * TILE_SIZE);
                tileData.push(tileID);
            }
            tiles.drawTiles(canvas, tileData);
        }
    }
}
