package meta.subState;
import polymod.Polymod.ModMetadata;
import openfl.display.BitmapData;
class ModMenuSubState extends MusicBeatSubState 
{
	var mods:Array<ModMetadata> = [];
	var alphabets:FlxTypedGroup<Alphabet>;
	var curSelected:Int = 0;
    var infoText:FlxText;
	override function create() 
    {
        var bg = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.updateHitbox();
		bg.scrollFactor.set();
        bg.alpha = 0;
		add(bg);

		FlxTween.tween(bg, {alpha: 0.5}, 0.25, {ease: FlxEase.cubeOut});

        mods = PolymodHandler.getAllMods();

        alphabets = new FlxTypedGroup<Alphabet>();
		for(mod in mods) {
			var a = new Alphabet(0, 0, mod.title, true);
            if (!Init.trueSettings.get('Enabled Mods').contains(mod.id)) 
                a.alpha = 0.6;
            
            var funiSprite:AttachedSprite = new AttachedSprite();
            funiSprite.loadGraphic(sys.FileSystem.exists(mod.iconPath) ? BitmapData.fromFile(mod.iconPath) : Paths.image('menus/base/title/newgrounds_logo'));
            funiSprite.setGraphicSize(Std.int(0.6 * funiSprite.width));
            funiSprite.updateHitbox();
            funiSprite.sprTracker = a;
            funiSprite.xAdd = a.width + 10;
            funiSprite.yAdd = -50;
            add(funiSprite);

			a.isMenuItem = true;
			a.scrollFactor.set();
			alphabets.add(a);
		}
		add(alphabets);

        infoText = new FlxText(5, FlxG.height - 24, 0, "", 32);
		infoText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoText.textField.background = true;
		infoText.textField.backgroundColor = FlxColor.BLACK;
		add(infoText);

        changeSelection(0, true);
    }

    public override function update(elapsed:Float) {
		super.update(elapsed);

        if(controls.UI_UP_P || controls.UI_DOWN_P) 
            changeSelection(controls.UI_UP_P ? -1 : 1);

		if (controls.ACCEPT) 
        {
            if (Init.trueSettings.get('Enabled Mods').contains(mods[curSelected].id))
            {
                FlxG.sound.play(Paths.sound('cancelMenu'));
                Init.trueSettings.get('Enabled Mods').remove(mods[curSelected].id);
                alphabets.members[curSelected].alpha = 0.6;
            }
            else
            {
                FlxG.sound.play(Paths.sound('confirmMenu'));
                Init.trueSettings.get('Enabled Mods').push(mods[curSelected].id);
                alphabets.members[curSelected].alpha = 1;
            }
		}

		if (controls.BACK)
        {
            Init.saveSettings();
            PolymodHandler.forceReloadAssets();
            close();
        }
	}


	var finalText:String;
	var textValue:String = '';
	var infoTimer:FlxTimer;

    public function changeSelection(change:Int, force:Bool = false) {
        if (change == 0 && !force) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, alphabets.length-1);

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.7);

		for(k=>alphabet in alphabets.members) alphabet.targetY = k - curSelected;

        var textValue = mods[curSelected].description;
        
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

    function regenInfoText()
    {
        if (infoTimer != null)
			infoTimer.cancel();
		if (infoText != null)
			infoText.text = "";
    }
}