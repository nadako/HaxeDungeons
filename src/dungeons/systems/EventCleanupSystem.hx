package dungeons.systems;

import nme.ObjectHash;

import de.polygonal.ds.Set;
import net.richardlord.ash.tools.ComponentPool;
import net.richardlord.ash.core.Entity;
import net.richardlord.ash.core.Game;
import net.richardlord.ash.core.System;

class EventCleanupSystem extends System
{
    private var config:ObjectHash<Class<Dynamic>, Bool>;
    private var toUpdate:ObjectHash<Entity, Bool>;

    public function new(config:ObjectHash<Class<Dynamic>, Bool>)
    {
        this.config = config;
    }

    override public function addToGame(game:Game):Void
    {
        game.entityAdded.add(addEntity);
        game.entityRemoved.add(removeEntity);
        for (entity in game.entities)
        {
            addEntity(entity);
        }
        toUpdate = new ObjectHash<Entity, Bool>();
    }

    override public function removeFromGame(game:Game):Void
    {
        game.entityAdded.remove(addEntity);
        game.entityRemoved.remove(removeEntity);
        for (entity in game.entities)
        {
            removeEntity(entity);
        }

        toUpdate = null;
    }

    private function addEntity(entity:Entity):Void
    {
        entity.componentAdded.add(onComponentAdded);
        for (componentClass in entity.components.keys())
        {
            onComponentAdded(entity, componentClass);
        }
    }

    private function removeEntity(entity:Entity):Void
    {
        entity.componentAdded.remove(onComponentAdded);
        toUpdate.remove(entity);
    }

    private function onComponentAdded(entity:Entity, componentClass:Class<Dynamic>):Void
    {
        if (config.exists(componentClass))
            toUpdate.set(entity, true);
    }

    override public function update(time:Float):Void
    {
        for (entity in toUpdate.keys())
        {
            for (componentClass in config.keys())
            {
                var component:Dynamic = entity.remove(componentClass);
                var toPool:Bool = config.get(componentClass);
                if (toPool)
                    ComponentPool.dispose(component);
            }
        }
        toUpdate = new ObjectHash<Entity, Bool>();
    }
}
