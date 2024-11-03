package meta.subState;
import sys.FileSystem;
import sys.io.File;
import polymod.Polymod.ModMetadata;
import openfl.utils.Assets;

//**Stolen from Codename Opppies**/
class ModMenuSubState extends MusicBeatSubState 
{
    var mods:Array<String> = [];
    var modpack:Array<ModMetadata> = [];
    var infoText:FlxText;
    var infoTimer:FlxTimer;
    var finalText:String;
    var grpText:FlxTypedGroup<Alphabet>;
    var curSelected:Int = 0;

    override function create() 
    {
        super.create();

        for(idk in PolymodHandler.getAllMods('mods'))  
            modpack.push(idk);
            
        modpack.push(makeBase());
        
        var bg = new FunkinSprite().makeSolidColor(FlxG.width, FlxG.height, 0xFF000000);
		bg.updateHitbox();
		bg.scrollFactor.set();
		add(bg);

		bg.alpha = 0;
		FlxTween.tween(bg, {alpha: 0.5}, 0.25, {ease: FlxEase.cubeOut});

        grpText = new FlxTypedGroup<Alphabet>();
        for(moddy in modpack)
        {
            var text = new Alphabet(0, 0, moddy.title, true);
			text.isMenuItem = true;
			text.scrollFactor.set();
			grpText.add(text);
        }
        add(grpText);

        infoText = new FlxText(5, FlxG.height - 24, 0, "Hi :)", 32);
		infoText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(infoText);
        regenInfoText();

		changeSelection();
    }

    function makeBase():ModMetadata {
        var lol = new ModMetadata();
        lol.id = "?";
        lol.title = "No Mod";
        lol.description = "this is base without any mod";
        lol.apiVersion = "0.1.0";
        lol.modVersion = "1.0.0";
        return lol;
    }

    private function regenInfoText()
	{
		if (infoTimer != null)
			infoTimer.cancel();
		if (infoText != null)
			infoText.text = "";
	}

    function setInfoText(?textValue:String = null)
    {
        if (textValue == null)
            textValue = "";

        if (finalText != textValue)
        {
            regenInfoText();

            var textSplit = [];
            finalText = textValue;
            textSplit = finalText.split("");

            var loopTimes = 0;
            infoTimer = new FlxTimer().start(0.025, function(tmr:FlxTimer)
            {
                //
                infoText.text += textSplit[loopTimes];
                infoText.screenCenter(X);

                loopTimes++;
            }, textSplit.length);
        }
    }

    override function update(elapsed:Float) 
    {
        super.update(elapsed);

        changeSelection((controls.DOWN_P ? 1 : 0) + (controls.UP_P ? -1 : 0));

        if (controls.ACCEPT) 
        {
            Init.trueSettings.set('Current Mod',  modpack[curSelected].id);
            trace('Current Mod ${Init.trueSettings.get('Current Mod')}');
            Init.saveSettings();
            reloadMod();
        }

        if (controls.BACK)
			close();
    }

    public function changeSelection(?change:Int = 0, ?force:Bool = false) 
    {
        if (change == 0 && !force) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, grpText.length-1);

        for(i=>text in grpText.members) {
			text.alpha = 0.6;
			text.targetY = i - curSelected;
		}
		grpText.members[curSelected].alpha = 1;

        setInfoText(modpack[curSelected].description);
    }

    var firstTime:Bool = true;
    function reloadMod() {
        PolymodHandler.forceReloadAssets();
        FlxG.resetState();
    }
}