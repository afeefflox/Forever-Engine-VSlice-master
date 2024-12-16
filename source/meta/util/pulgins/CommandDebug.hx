package meta.util.pulgins;

class CommandDebug extends FlxBasic
{
    public function new()
    {
        super();
    }

    public static function initialize():Void
    {
        FlxG.plugins.addPlugin(new CommandDebug());
    }

    public override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.F9)
        {
            WindowUtil.allocConsole();
            WindowUtil.clearScreen();            
        }
    }
}