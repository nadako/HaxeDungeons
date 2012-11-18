package dungeons;

import dungeons.components.Description;
import net.richardlord.ash.core.Entity;

import dungeons.components.PlayerControls;

class EntityUtils
{
    public static inline function isPlayer(entity:Entity):Bool
    {
        return entity.has(PlayerControls);
    }

    public static inline function getName(entity:Entity):String
    {
        var desc:Description = entity.get(Description);
        if (desc != null)
            return desc.name;
        else
            return "something";
    }
}
