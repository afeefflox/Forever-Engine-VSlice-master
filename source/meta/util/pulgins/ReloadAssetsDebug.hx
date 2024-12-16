package meta.util.pulgins;

class ReloadAssetsDebug extends FlxBasic
{
    public function new()
    {
        super();
    }

    public static function initialize():Void
    {
        FlxG.plugins.addPlugin(new ReloadAssetsDebug());
    }

    public override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.F5)
        {
            PolymodHandler.forceReloadAssets();
            // Create a new instance of the current state, so old data is cleared.
            FlxG.resetState();
        }
    }
}