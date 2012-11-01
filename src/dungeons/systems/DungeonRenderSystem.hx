package dungeons.systems;

import nme.display.Tilesheet;
import nme.display.Graphics;

import de.polygonal.ds.Array2;
import net.richardlord.ash.core.NodeList;
import net.richardlord.ash.core.Game;
import net.richardlord.ash.core.System;

import dungeons.Dungeon.Tile;

class DungeonRenderSystem extends System
{
/*
    private var canvas:Graphics;
    private var tiles:Tilesheet;
    private var nodeList:NodeList<DungeonTileNode>;
    private var needUpdate:Bool;
    private var dungeonGrid:Array2<Tile>;

    public function new(canvas:Graphics, tiles:Tilesheet, dungeonGrid:Array2<Tile>)
    {
        this.canvas = canvas;
        this.tiles = tiles;
        this.dungeonGrid = dungeonGrid;
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
            var tileData:Array<Float> = new Array<Float>();
            for (node in nodeList)
            {
                var tileID:Float;
                switch (node.renderable.tile)
                {
                    case Wall:
                        tileID = isVerticalWall(node.position.x, node.position.y) ? 1 : 0;
                    case Floor:
                        tileID = 2;
                    default:
                        continue;
                }
                tileData.push(node.position.x * Constants.TILE_SIZE);
                tileData.push(node.position.y * Constants.TILE_SIZE);
                tileData.push(tileID);
            }
            tiles.drawTiles(canvas, tileData);
        }
    }

    private function isVerticalWall(x:Int, y:Int):Bool
    {
        return dungeonGrid.inRange(x, y + 1) && dungeonGrid.get(x, y + 1) == Wall;
    }
*/
}
