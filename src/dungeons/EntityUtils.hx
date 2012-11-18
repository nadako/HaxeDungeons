package dungeons;

import dungeons.components.Description;
import net.richardlord.ash.core.Entity;

import dungeons.components.PlayerControls;

/**
 * Helper class for getting info on entities.
 * Use with "using dungeons.EntityUtils"
 **/
class EntityUtils
{
    /**
     * Is this entity a player?
     **/
    public static inline function isPlayer(entity:Entity):Bool
    {
        return entity.has(PlayerControls);
    }

    /**
     * Get a sensible name string for given entity.
     **/
    public static inline function getName(entity:Entity):String
    {
        var desc:Description = entity.get(Description);
        if (desc != null)
            return desc.name;
        else
            return "something";
    }
}
