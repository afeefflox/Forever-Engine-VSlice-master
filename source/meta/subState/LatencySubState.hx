package meta.subState;

import haxe.Timer;

class LatencySubState extends MusicBeatSubState
{
    var visualOffsetText:FlxText;
    var offsetText:FlxText;
    var noteGrp:Array<SongNoteData> = [];
    var strumLine:Strumline;
  
    var blocks:FlxTypedGroup<FlxSprite>;
  
    var songPosVis:FlxSprite;
    var songVisFollowVideo:FlxSprite;
    var songVisFollowAudio:FlxSprite;
  
    var beatTrail:FlxSprite;
    var diffGrp:FlxTypedGroup<FlxText>;
    var offsetsPerBeat:Array<Null<Int>> = [];
    var swagSong:HomemadeMusic;
  
    var previousVolume:Float;
  
    var stateCamera:FlxCamera;

    var prevPersistentDraw:Bool;
    var prevPersistentUpdate:Bool;
    
    override function create()
    {
        super.create();

        prevPersistentDraw = FlxG.state.persistentDraw;
        prevPersistentUpdate = FlxG.state.persistentUpdate;
    
        FlxG.state.persistentDraw = false;
        FlxG.state.persistentUpdate = false;

        stateCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
        stateCamera.bgColor = FlxColor.BLACK;
        FlxG.cameras.add(stateCamera);
    
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        add(bg);

        if (FlxG.sound.music != null)
        {
            previousVolume = FlxG.sound.music.volume;
            FlxG.sound.music.volume = 0; // only want to mute the volume, incase we are coming from pause menu
        }
        else
            previousVolume = 1;

        swagSong = new HomemadeMusic();
        swagSong.loadEmbedded(Paths.sound('soundTest'), true);
        swagSong.looped = true;
        swagSong.play();
        FlxG.sound.list.add(swagSong);

        Conductor.instance.forceBPM(60);

        diffGrp = new FlxTypedGroup<FlxText>();
        add(diffGrp);
    
        for (beat in 0...Math.floor(swagSong.length / (Conductor.instance.stepLengthMs * 2)))
        {
            var beatTick:FlxSprite = new FlxSprite(songPosToX(beat * (Conductor.instance.stepLengthMs * 2)), FlxG.height - 15);
            beatTick.makeGraphic(2, 15);
            beatTick.alpha = 0.3;
            add(beatTick);
      
            var offsetTxt:FlxText = new FlxText(songPosToX(beat * (Conductor.instance.stepLengthMs * 2)), FlxG.height - 26, 0, "");
            offsetTxt.alpha = 0.5;
            diffGrp.add(offsetTxt);
      
            offsetsPerBeat.push(null);
        }

        songVisFollowAudio = new FlxSprite(0, FlxG.height - 20).makeGraphic(2, 20, FlxColor.YELLOW);
        add(songVisFollowAudio);
    
        songVisFollowVideo = new FlxSprite(0, FlxG.height - 20).makeGraphic(2, 20, FlxColor.BLUE);
        add(songVisFollowVideo);
    
        songPosVis = new FlxSprite(0, FlxG.height - 20).makeGraphic(2, 20, FlxColor.RED);
        add(songPosVis);
    
        beatTrail = new FlxSprite(0, songPosVis.y).makeGraphic(2, 20, FlxColor.PURPLE);
        beatTrail.alpha = 0.7;
        add(beatTrail);

        blocks = new FlxTypedGroup<FlxSprite>();
        add(blocks);
    
        for (i in 0...8)
        {
            var block = new FlxSprite(2, ((FlxG.height / 8) + 2) * i).makeGraphic(Std.int(FlxG.height / 8), Std.int((FlxG.height / 8) - 4));
            block.alpha = 0.1;
            blocks.add(block);
        }

        var strumlineBG:FlxSprite = new FlxSprite();
        add(strumlineBG);
    
        strumLine = new Strumline(NoteStyleRegistry.instance.fetchDefault(), true);
        strumLine.screenCenter();
        add(strumLine);
    

        strumlineBG.x = strumLine.x;
        strumlineBG.makeGraphic(Std.int(strumLine.width), FlxG.height, 0xFFFFFFFF);
        strumlineBG.alpha = 0.1;
    
        visualOffsetText = new FlxText();
        visualOffsetText.setFormat(Paths.font("vcr.ttf"), 20);
        visualOffsetText.x = (FlxG.height / 8) + 10;
        visualOffsetText.y = 10;
        visualOffsetText.fieldWidth = strumLine.x - visualOffsetText.x - 10;
        add(visualOffsetText);

        offsetText = new FlxText();
        offsetText.setFormat(Paths.font("vcr.ttf"), 20);
        offsetText.x = strumLine.x + strumLine.width + 10;
        offsetText.y = 10;
        offsetText.fieldWidth = FlxG.width - offsetText.x - 10;
        add(offsetText);
    
        var helpText:FlxText = new FlxText();
        helpText.setFormat(Paths.font("vcr.ttf"), 20);
        helpText.text = "Press BACK to return to main menu";
        helpText.x = FlxG.width - helpText.width;
        helpText.y = FlxG.height - (helpText.height * 2) - 2;
        add(helpText);
    
        regenNoteData();        

        if (!Init.trueSettings.get('Controller Mode'))
			initialize();
    }

    function initialize():Void
    {
        FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
    }

    function deinitialize():Void
    {
        FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
    }

    function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...PlayState.keysArray.length)
			{
				for (j in 0...PlayState.keysArray[i].length)
				{
					if (key == PlayState.keysArray[i][j])
						return i;
				}
			}
		}
		return -1;
	}

    function onKeyPress(event:KeyboardEvent):Void
    {
        var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if (key >= 0 && FlxG.keys.checkStatus(eventKey, JUST_PRESSED) && FlxG.keys.enabled)
        {
            strumLine.pressKey(Strumline.DIRECTIONS[key]);
            strumLine.playPress(Strumline.DIRECTIONS[key]);
        }
    }

    function onKeyRelease(event:KeyboardEvent):Void
    {
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

        if (FlxG.keys.enabled)
        {
			if (key >= 0) strumLine.playStatic(Strumline.DIRECTIONS[key]);
        }
    }

    //Yeah with Controller what do you expect lol
    function controllerInput()
    {
        var justPressArray:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];

		var justReleaseArray:Array<Bool> = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];

		if (justPressArray.contains(true))
		{
			for (i in 0...justPressArray.length)
			{
				if (justPressArray[i])
					onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, PlayState.keysArray[i][0]));
			}
		}

		if (justReleaseArray.contains(true))
		{
			for (i in 0...justReleaseArray.length)
			{
				if (justReleaseArray[i])
					onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, PlayState.keysArray[i][0]));
			}
		}
    }

    override public function close():Void
    {
        cleanup();
        super.close();
    }

    function cleanup():Void
    {
        if (!Init.trueSettings.get('Controller Mode')) deinitialize();
        if (FlxG.sound.music != null)  FlxG.sound.music.volume = previousVolume;
        swagSong.stop();
        FlxG.sound.list.remove(swagSong);
    
        FlxG.cameras.remove(stateCamera);
    
        FlxG.state.persistentDraw = prevPersistentDraw;
        FlxG.state.persistentUpdate = prevPersistentUpdate;
    }

    function regenNoteData()
    {
        for (i in 0...32)
        {
            var note:SongNoteData = new SongNoteData((Conductor.instance.stepLengthMs * 2) * i, 1);
            noteGrp.push(note);
        }
        strumLine.applyNoteData(noteGrp);
    }

    override function stepHit()
    {
        super.stepHit();

        if (Conductor.instance.currentStep % 4 == 2)  blocks.members[((Conductor.instance.currentBeat % 8) + 1) % 8].alpha = 0.5;
    }

    override function beatHit()
    {
        super.beatHit();

        if (Conductor.instance.currentBeat % 8 == 0) blocks.forEach(blok -> {
            blok.alpha = 0.1;
        });

        blocks.members[Conductor.instance.currentBeat % 8].alpha = 1;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        Conductor.instance.update(swagSong.time, false);

        generateBeat();
        
        if (Init.trueSettings.get('Controller Mode')) controllerInput();

        songPosVis.x = songPosToX(Conductor.instance.songPosition);
        songVisFollowAudio.x = songPosToX(Conductor.instance.songPosition - Conductor.instance.audioVisualOffset);
        songVisFollowVideo.x = songPosToX(Conductor.instance.songPosition - Conductor.instance.inputOffset);
    
        visualOffsetText.text = "Visual Offset: " + Conductor.instance.audioVisualOffset + "ms";
        visualOffsetText.text += "\n\nYou can press SPACE+Left/Right to change this value.";
        visualOffsetText.text += "\n\nYou can hold SHIFT to step 1ms at a time";
    
        offsetText.text = "INPUT Offset (Left/Right to change): " + Conductor.instance.inputOffset + "ms";
        offsetText.text += "\n\nYou can hold SHIFT to step 1ms at a time";

        var avgOffsetInput:Float = 0;

        var loopInd:Int = 0;
        for (offsetThing in offsetsPerBeat)
        {
            if (offsetThing == null) continue;
            avgOffsetInput += offsetThing;
            loopInd++;
        }

        avgOffsetInput /= loopInd;

        offsetText.text += "\n\nEstimated average input offset needed: " + avgOffsetInput;
    
        var multiply:Int = 10;
    
        if (FlxG.keys.pressed.SHIFT) multiply = 1;

        if (FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.SPACE)
        {
            if (FlxG.keys.justPressed.RIGHT) Conductor.instance.audioVisualOffset += 1 * multiply;
            if (FlxG.keys.justPressed.LEFT) Conductor.instance.audioVisualOffset -= 1 * multiply;
        }
        else
        {
            if (FlxG.keys.anyJustPressed([LEFT, RIGHT]))
            {
                if (FlxG.keys.justPressed.RIGHT) Conductor.instance.inputOffset += 1 * multiply;
                if (FlxG.keys.justPressed.LEFT)   Conductor.instance.inputOffset -= 1 * multiply;

                offsetsPerBeat = [];
                diffGrp.forEach(memb -> memb.text = "");
            }
        }

        if (controls.BACK) close();
    }

    function generateBeat() {
        var closestBeat:Int = Math.round(Conductor.instance.getTimeWithDiff(swagSong) / (Conductor.instance.stepLengthMs * 2)) % diffGrp.members.length;
        var getDiff:Float = Conductor.instance.getTimeWithDiff(swagSong) - (closestBeat * (Conductor.instance.stepLengthMs * 2));
        getDiff -= Conductor.instance.audioVisualOffset;

        if (closestBeat == 0 && getDiff >= Conductor.instance.stepLengthMs * 2) getDiff -= swagSong.length;

        beatTrail.x = songPosVis.x;
    
        diffGrp.members[closestBeat].text = getDiff + "ms";
        offsetsPerBeat[closestBeat] = Math.round(getDiff);
    }

    function songPosToX(pos:Float):Float return FlxMath.remapToRange(pos, 0, swagSong.length, 0, FlxG.width);
}

class HomemadeMusic extends FlxSound
{
  public var prevTimestamp:Int = 0;

  public function new()
  {
    super();
  }

  var prevTime:Float = 0;

  override function update(elapsed:Float)
  {
    super.update(elapsed);
    if (prevTime != time)
    {
      prevTime = time;
      prevTimestamp = Std.int(Timer.stamp() * 1000);
    }
  }

  public function getTimeWithDiff():Float
  {
    return time + (Std.int(Timer.stamp() * 1000) - prevTimestamp);
  }
}