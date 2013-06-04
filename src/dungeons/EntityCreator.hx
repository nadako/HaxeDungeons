package dungeons;

import haxe.Json;

import ash.core.Engine;
import ash.core.Entity;

import openfl.Assets;

import com.haxepunk.HXP;

import dungeons.components.Item;
import dungeons.components.Equipment;
import dungeons.components.Description;
import dungeons.components.Obstacle;
import dungeons.components.Renderable;
import dungeons.components.PlayerControls;
import dungeons.components.MonsterAI;
import dungeons.components.Actor;
import dungeons.components.Position;
import dungeons.components.CameraFocus;
import dungeons.components.FOV;
import dungeons.components.Health;
import dungeons.components.HealthRegen;
import dungeons.components.Fighter;
import dungeons.components.Inventory;

import dungeons.systems.RenderSystem.RenderLayers;

using dungeons.utils.ArrayUtil;

class EntityCreator
{
    private var weaponDefs:Array<WeaponDefinition>;
    private var monsterDefs:Array<MonsterDefinition>;

    private var engine:Engine;
    private var obstacle:Obstacle;

    public function new(engine:Engine)
    {
        this.engine = engine;

        // singleton components used by many entities
        obstacle = new Obstacle();

        // game definitions
        weaponDefs = cast Json.parse(Assets.getText("weapons.json"));
        monsterDefs = cast Json.parse(Assets.getText("monsters.json"));
    }

    public function createPlayer():Entity
    {
        var player:Entity = new Entity(Entities.PLAYER);
        player.add(new Renderable("player", RenderLayers.CHARACTER));
        player.add(new PlayerControls());
        player.add(new Actor(Std.int(Constants.TICK_ENERGY * 1.5)));
        player.add(new Position());
        player.add(new CameraFocus());
        player.add(new FOV(10));
        player.add(new Health(50));
        player.add(new HealthRegen(3));
        player.add(new Fighter(5, 1));
        player.add(new Inventory());
        player.add(obstacle);
        engine.addEntity(player);
        return player;
    }

    public function createGold(quantity:Int):Entity
    {
        var gold:Entity = new Entity();
        gold.add(new Item("gold", true, quantity));
        gold.add(new Position());
        gold.add(new Renderable("gold" + (1 + HXP.rand(15))));
        gold.add(new Description("Gold"));
        engine.addEntity(gold);
        return gold;
    }

    public function createWeapon():Entity
    {
        var weaponDef:WeaponDefinition = weaponDefs.randomChoice();
        var weapon:Entity = new Entity();
        weapon.add(new Item(weaponDef.name, false, 1));
        weapon.add(new Equipment(EquipSlot.Weapon, weaponDef.atk));
        weapon.add(new Position());
        weapon.add(new Renderable(weaponDef.tile));
        weapon.add(new Description(weaponDef.name));
        engine.addEntity(weapon);
        return weapon;
    }

    public function createMonster():Entity
    {
        var monsterDef:MonsterDefinition = monsterDefs.randomChoice();
        var monster:Entity = new Entity();
        monster.add(new Description(monsterDef.name));
        monster.add(new Renderable(monsterDef.tile, RenderLayers.CHARACTER, false));
        monster.add(new Position());
        monster.add(new Actor(Constants.TICK_ENERGY));
        monster.add(new Health(monsterDef.hp));
        monster.add(new Fighter(monsterDef.power, monsterDef.defense));
        monster.add(obstacle);
        monster.add(new MonsterAI());
        engine.addEntity(monster);
        return monster;
    }

    public function createRemains():Entity
    {
        var remains:Entity = new Entity();
        remains.add(new Position());
        if (HXP.random < 0.5)
            remains.add(new Renderable("blood" + HXP.rand(15)));
        else
            remains.add(new Renderable("bones" + HXP.rand(9)));
        engine.addEntity(remains);
        return remains;
    }
}


private typedef WeaponDefinition =
{
    var name:String;
    var tile:String;
    var atk:Int;
}


private typedef MonsterDefinition =
{
    var name:String;
    var tile:String;
    var hp:Int;
    var power:Int;
    var defense:Int;
}
