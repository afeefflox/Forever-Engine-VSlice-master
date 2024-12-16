package meta.util.pulgins;

class EvacuateDebug extends FlxBasic
{
    public function new()
    {
        super();
    }

    public static function initialize():Void
    {
        FlxG.plugins.addPlugin(new EvacuateDebug());
    }

    public override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.F4) FlxG.switchState(() -> new meta.state.menus.MainMenuState());
    }
}