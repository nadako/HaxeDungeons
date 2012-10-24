package components;

class Behaviour
{
    public var type(default, null):BehaviourType;

    public function new(type:BehaviourType)
    {
        this.type = type;
    }
}


enum BehaviourType
{
    Player;
}
