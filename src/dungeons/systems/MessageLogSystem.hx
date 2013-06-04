package dungeons.systems;

import flash.text.TextField;

import ash.core.System;

class MessageLogSystem extends System
{
    private var textField:TextField;
    private var maxLines:Int;
    private var messages:Array<String>;
    private static var _instance:MessageLogSystem;

    public function new(textField:TextField, maxLines:Int)
    {
        super();

        if (_instance != null)
            throw "Only one MessageLogSystem can be created";
        _instance = this;

        this.textField = textField;
        this.maxLines = maxLines;
        messages = [];
    }

    public static function message(text:String):Void
    {
        _instance.messages.push(text);
    }

    override public function update(dt:Float):Void
    {
        if (messages.length > 0)
        {
            textField.appendText(messages.shift() + "\n");
            while (textField.numLines > maxLines)
                textField.text = textField.text.substr(textField.getLineOffset(1));
        }
    }
}
