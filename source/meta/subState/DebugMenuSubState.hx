package meta.subState;

import meta.state.editors.*;
import flixel.addons.transition.FlxTransitionableState;

class DebugMenuSubState extends MusicBeatSubState
{
    var options:Array<String> = [
		'Character Editor',
		'Charting Editor'
	];
	private var grpTexts:FlxTypedGroup<Alphabet>;
    private var curSelected = 0;
    var camFocusPoint:FlxObject;

    override function create()
    {
        super.create();
        FlxTransitionableState.skipNextTransIn = true;

        camFocusPoint = new FlxObject(0, 0);
        add(camFocusPoint);
    
        // Follow the camera focus as we scroll.
        FlxG.camera.follow(camFocusPoint, null, 0.06);
        FlxG.camera.focusOn(new FlxPoint(camFocusPoint.x, camFocusPoint.y + 500));


        var menuBG = new FlxSprite().loadGraphic(Paths.image('menus/base/menuDesat'));
        menuBG.color = 0xFF4CAF50;
        menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
        menuBG.updateHitbox();
        menuBG.screenCenter();
        menuBG.scrollFactor.set();
        add(menuBG);

        grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);
        
		for (i in 0...options.length)
		{
			var leText:Alphabet = new Alphabet(90, 320, options[i], true);
            leText.screenCenter();
            leText.y += (100 * (i - (options.length / 2))) + 50;
			grpTexts.add(leText);
		}
        changeSelection();
    }

    override function update(elapsed:Float)
    {
        if(controls.UI_UP_P || controls.UI_DOWN_P) changeSelection(controls.UI_UP_P ? -1 : 1);

        if (controls.BACK)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            this.close();
        }

        if (controls.ACCEPT)
        {
            switch(options[curSelected]) {
				case 'Character Editor':
					FlxG.switchState(new CharacterEditorState());
				case 'Charting Editor':
                    FlxG.switchState(new meta.state.editors.charting.ChartEditorState());
			}
            FlxG.sound.music.volume = 0;
        }

        var bullShit:Int = 0;
		for (item in grpTexts.members)
		{
            item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) item.alpha = 1;
		}

        camFocusPoint.setPosition(grpTexts.members[curSelected].x + grpTexts.members[curSelected].width / 2, grpTexts.members[curSelected].y + grpTexts.members[curSelected].height / 2);

    }

    function changeSelection(change:Int = 0)
	{
		if(change != 0)
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;
	}
}