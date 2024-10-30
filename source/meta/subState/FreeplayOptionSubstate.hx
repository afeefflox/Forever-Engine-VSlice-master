package meta.subState;

import gameObjects.userInterface.menu.AttachedText;
import meta.state.menus.FreeplayState;

//Yeah Based on Psych Stuff
class FreeplayOptionSubstate extends MusicBeatSubState
{
    private var curSelected:Int = 0;
	private var optionsArray:Array<Dynamic> = [];

	private var grpOptions:FlxTypedGroup<Alphabet>;
    private var checkboxGroup:FlxTypedGroup<Checkmark>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

    private var curOption(get, never):FreeplayOption;
	function get_curOption() return optionsArray[curSelected]; //shorter lol

    private var instance(get, never):FreeplayState;
    function get_instance() return FreeplayState.instance; //shorter lol

	private var targetSong(get, never):Song;
	function get_targetSong() return instance.songs[instance.curSelected].data; //shorter lol

    function getOptions()
    {
        var option:FreeplayOption = new FreeplayOption('Character Variation', instance.currentCharacter, STRING, 'bf', ["bf", "pico"]);
		optionsArray.push(option);


		/*
		var targetDifficulty:Null<SongDifficulty> = targetSong.getDifficulty(instance.currentDifficulty, instance.currentVariation);
		if (targetDifficulty == null)
		{
			FlxG.log.warn('WARN: could not find difficulty with id (${instance.currentDifficulty})');
			return;
		}
		var baseInstrumentalId:String = targetSong.getBaseInstrumentalId(instance.currentDifficulty, targetDifficulty?.variation ?? Constants.DEFAULT_VARIATION) ?? '';
		var altInstrumentalIds:Array<String> = targetSong.listAltInstrumentalIds(instance.currentDifficulty, targetDifficulty?.variation ?? Constants.DEFAULT_VARIATION) ?? [];
	
		if (altInstrumentalIds.length > 0)
		{
			var instrumentalIds = [baseInstrumentalId].concat(altInstrumentalIds);
			var option:FreeplayOption = new FreeplayOption('Alt Instrumental', instance.currentInstrumental, STRING, instrumentalIds[0], instrumentalIds);
			optionsArray.push(option);
		}
			*/
    }

	public function getOptionByName(name:String)
	{
		for(i in optionsArray)
		{
			var opt:FreeplayOption = i;
			if (opt.name == name)
				return opt;
		}
		return null;
	}

	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<Checkmark>();
		add(checkboxGroup);
		
		getOptions();

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(150, 360, optionsArray[i].name, true, 0.8);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if(optionsArray[i].type != BOOL)
			{
				var valueText:AttachedText = new AttachedText(Std.string(optionsArray[i].values), optionText.width + 40, 0, true, 0.8);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				valueText.x += 10;
				grpTexts.add(valueText);
				optionsArray[i].setChild(valueText);
			}
			updateTextFrom(optionsArray[i]);
		}

		changeSelection();
	}

	
	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.UI_UP_P || controls.UI_DOWN_P)
			changeSelection(controls.UI_UP_P ? -1 : 1);

		if (controls.BACK)
		{
			close();
			FreeplayState.rememberedCharacter = instance.currentCharacter = optionsArray[0].values;
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept <= 0)
		{
			if(curOption.type != BOOL)
			{
				if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
					if(holdTime > 0.5 || pressed)
					{
						if(pressed)
						{
							var add:Dynamic = null;
							if(curOption.type != STRING) add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
								
							switch(curOption.type)
							{
								case INT, FLOAT, PERCENT:
									holdValue = curOption.values + add;
									if(holdValue < curOption.minValue) holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

									switch(curOption.type)
									{
										case INT:
											holdValue = Math.round(holdValue);
											curOption.values = holdValue;

										case FLOAT, PERCENT:
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.values = holdValue;
										default:
									}
								case STRING:
									var num:Int = curOption.curOption; //lol
									if(controls.UI_LEFT_P) --num;
									else num++;

									if(num < 0)
										num = curOption.options.length - 1;
									else if(num >= curOption.options.length)
										num = 0;

									curOption.curOption = num;
									curOption.values = curOption.options[num]; //lol
								default:
							}

							updateTextFrom(curOption);
							curOption.change();
							FlxG.sound.play(Paths.sound('scrollMenu'));							
						}
						else if(curOption.type != STRING)
						{
							holdValue = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue + curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1)));

							switch(curOption.type)
							{
								case INT:
									curOption.values = Math.round(holdValue);
								
								case FLOAT, PERCENT:
									var blah:Float = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue + curOption.changeValue - (holdValue % curOption.changeValue)));
									curOption.values = FlxMath.roundDecimal(blah, curOption.decimals);
								default:
							}
							holdTime += elapsed;

							updateTextFrom(curOption);
							curOption.change();
						}

					}
				}
				else if(controls.UI_LEFT_R || controls.UI_RIGHT_R)
					clearHold();
			}

			if(controls.RESET)
			{
				for (i in 0...optionsArray.length)
				{
					var leOption:FreeplayOption = optionsArray[i];
					leOption.values = leOption.defaultValue;
					if(leOption.type != BOOL)
					{
						if(leOption.type == STRING)
							leOption.curOption = leOption.options.indexOf(leOption.values);

						updateTextFrom(leOption);
					}
					leOption.change();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		}

		if(nextAccept > 0) nextAccept -= 1;
	}

	function updateTextFrom(option:FreeplayOption) {
		var text:String = option.displayFormat;
		var val:Dynamic = option.values;
		if(option.type == PERCENT) val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold()
	{
		if(holdTime > 0.5)
			FlxG.sound.play(Paths.sound('scrollMenu'));
		holdTime = 0;
	}

	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, optionsArray.length - 1);
		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			item.alpha = (item.targetY == 0) ? 1 : 0.6;
		}
		for (text in grpTexts)
		{
			text.alpha = (text.ID == curSelected) ? 1 : 0.6;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}

class FreeplayOption
{
    private var child:Alphabet;
	public var text(default, set):String;
	public var onChange:Void->Void = null;
	public var type:OptionType = BOOL;
    public var values:Dynamic;

    public var scrollSpeed:Float = 50; //Only works on int/float, defines how fast it scrolls per second while holding left/right
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; //Don't change this
	public var options:Array<String> = null; //Only used in string type
	public var changeValue:Dynamic = 1; //Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; //Only used in int/float/percent type
	public var maxValue:Dynamic = null; //Only used in int/float/percent type
	public var decimals:Int = 1; //Only used in float/percent type

	public var displayFormat:String = '%v'; //How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var name:String = 'Unknown';

    public function new(name:String, values:Dynamic, type:OptionType, defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null)
    {
		this.name = name;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;
        this.values = values;

        if(defaultValue == 'null variable value')
		{
			switch(type)
			{
				case BOOL:
					defaultValue = false;
				case INT, FLOAT:
					defaultValue = 0;
				case PERCENT:
					defaultValue = 1;
				case STRING:
					defaultValue = '';
					if(options.length > 0)
						defaultValue = options[0];

				default:
			}
		}

        if(values == null) values = defaultValue;
			
        switch(type)
		{
			case STRING:
				var num:Int = options.indexOf(values);
				if(num > -1)
					curOption = num;

			case PERCENT:
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;

			default:
		}
    }

    public function change()
    {
        if(onChange != null) onChange();
    }

    public function setChild(child:Alphabet)
		this.child = child;

    private function set_text(value:String = '')
	{
		if(child != null) child.text = value;
		return value;
	}
}

enum OptionType {
	// Bool will use checkboxes
	// Everything else will use a text
	BOOL;
	INT;
	FLOAT;
	PERCENT;
	STRING;
	KEYBIND;
}
