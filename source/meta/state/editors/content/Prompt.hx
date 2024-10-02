package meta.state.editors.content;

import flixel.util.FlxDestroyUtil;

import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUINumericStepper;

class ExitConfirmationPrompt extends Prompt
{
	public function new(?finishCallback:Void->Void)
	{
		super('There\'s unsaved progress,\nare you sure you want to exit?', function()
		{
			FlxG.mouse.visible = false;
			FlxG.switchState(new MainMenuState());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			if(finishCallback != null) finishCallback();
		}, 'Exit');
	}
}

// A Simple Prompt with "OK" and "Cancel" that covers most case usages
class Prompt extends BasePrompt
{
	var yesFunction:Void->Void;
	var noFunction:Void->Void;
	var _yesTxt:String = 'OK';
	var _noTxt:String = 'Cancel';
	public function new(title:String, yesFunction:Void->Void, ?noFunction:Void->Void, ?_yesTxt:String, ?_noTxt:String)
	{
		if(_yesTxt != null) this._yesTxt = _yesTxt;
		if(_noTxt != null) this._noTxt = _noTxt;
		this.yesFunction = yesFunction;
		this.noFunction = noFunction;
		super(title, promptCreate);
	}

	function promptCreate(_)
	{
		var btnY = 390;
        var btn:FlxUIButton = new FlxUIButton(0, btnY, _yesTxt, function()
		{
			yesFunction();
			close();
		});
		btn.color = FlxColor.RED;
		btn.label.color = FlxColor.WHITE;
		btn.screenCenter(X);
		btn.x -= 100;
		btn.cameras = cameras;
		add(btn);

		var btn:FlxUIButton = new FlxUIButton(0, btnY, _noTxt, close);
		btn.screenCenter(X);
		btn.x += 100;
		btn.cameras = cameras;
		add(btn);
	}

	override function close()
	{
		if(noFunction != null) noFunction();
		super.close();
	}
}

class BasePrompt extends MusicBeatSubState
{
	var _sizeX:Float = 0;
	var _sizeY:Float = 0;
	var _title:String;

	public var onCreate:BasePrompt->Void;
	public var onUpdate:BasePrompt->Float->Void;
	public function new(?sizeX:Float = 420, ?sizeY:Float = 160, title:String, ?onCreate:BasePrompt->Void, ?onUpdate:BasePrompt->Float->Void)
	{
		this._sizeX = sizeX;
		this._sizeY = sizeY;
		this._title = title;
		this.onCreate = onCreate;
		this.onUpdate = onUpdate;
		super();
	}

	public var bg:FlxSprite;
	public var titleText:FlxText;
	override function create()
	{
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.alpha = 0.8;
		bg.scale.set(_sizeX, _sizeY);
		bg.updateHitbox();
		bg.screenCenter();
		bg.cameras = cameras;
		add(bg);
		
		titleText = new FlxText(0, bg.y + 30, 400, _title, 16);
		titleText.screenCenter(X);
		titleText.alignment = CENTER;
		titleText.cameras = cameras;
		add(titleText);
		
		if(onCreate != null)
			onCreate(this);
		super.create();
	}

	var _blockInput:Float = 0.1;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		_blockInput = Math.max(0, _blockInput - elapsed);
		if(_blockInput <= 0 && FlxG.keys.justPressed.ESCAPE)
		{
			close();
			return;
		}

		if(onUpdate != null)
			onUpdate(this, elapsed);
	}

	override function destroy()
	{
		for (member in members)
        {
            if (member is FlxUIInputText) {
                if (ChartingState.instance.blockPressWhileTypingOn.indexOf(cast member) != -1) {
                    ChartingState.instance.blockPressWhileTypingOn.remove(cast member);
                }
            }  
            if (member is FlxUINumericStepper) {
                if (ChartingState.instance.blockPressWhileTypingOnStepper.indexOf(cast member) != -1) {
                    ChartingState.instance.blockPressWhileTypingOnStepper.remove(cast member);
                }
            }            
            if (member is FlxUIDropDownMenu) {
                if (ChartingState.instance.blockPressWhileScrolling.indexOf(cast member) != -1) {
                    ChartingState.instance.blockPressWhileScrolling.remove(cast member);
                }
            }        
            FlxDestroyUtil.destroy(member);           
        } 
		super.destroy();
	}
}