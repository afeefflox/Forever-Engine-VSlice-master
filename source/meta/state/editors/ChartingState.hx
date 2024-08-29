package meta.state.editors;

import flash.geom.Rectangle;
import haxe.Json;
import haxe.format.JsonParser;
import haxe.io.Bytes;

import flixel.FlxObject;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxGroup;
import flixel.ui.FlxButton;

import flixel.util.FlxSort;
import lime.media.AudioBuffer;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;

import meta.data.font.AttachedFlxText;

@:access(flixel.sound.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)

class ChartingState extends MusicBeatState
{
	public var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	public var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	public var blockPressWhileScrolling:Array<FlxUIDropDownMenu> = [];

    var _file:FileReference;

	var UI_box:FlxUITabMenu;

	public static var goToPlayState:Bool = false;
	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public static var curSection:Int = 0;
	public static var lastSection:Int = 0;
	private static var lastSong:String = '';

	var bpmTxt:FlxText;

	var camPos:FlxObject;
	var strumLine:FlxSprite;
	var curSong:String = 'Test';
	var amountSteps:Int = 0;

	var highlight:FlxSprite;

	public static var GRID_SIZE:Int = 40;
	var CAM_OFFSET:Int = 360;

	var dummyArrow:FlxSprite;

	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedEvents:FlxTypedSpriteGroup<Note>; //fixing offsets :/
	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedNoteType:FlxTypedGroup<FlxText>;

	var nextRenderedSustains:FlxTypedGroup<FlxSprite>;
	var nextRenderedNotes:FlxTypedGroup<Note>;
	var nextRenderedEvents:FlxTypedSpriteGroup<Note>;

	var gridBG:FlxSprite;
	var nextGridBG:FlxSprite;

	
	var _song:SwagSong;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic> = null;
	var curSelectedEvent:Array<Dynamic> = null;
	var playbackSpeed:Float = 1;

	var vocals:FlxSound = null;
	var opponentVocals:FlxSound = null;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;
	var currentSongName:String;

	var zoomTxt:FlxText;

	var zoomList:Array<Float> = [
		0.25,
		0.5,
		1,
		2,
		3,
		4,
		6,
		8,
		12,
		16,
		24
	];
	var curZoom:Int = 2;

	public static var instance:ChartingState;


	var waveformSprite:FlxSprite;
	var gridLayer:FlxTypedGroup<FlxSprite>;

	public static var quantization:Int = 16;
    override function create()
    {
        super.create();

		instance = this;
		if (PlayState.SONG != null)
			_song = Song.checkSong(PlayState.SONG);
		else
		{
			_song = Song.DEFAULT_SONG;
			addSection();
			PlayState.SONG = _song;
		}
		

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/base/menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF2C0781;
		add(bg);

        gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);

		waveformSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(1, 1, 0x00FFFFFF);
		add(waveformSprite);

        leftIcon = new HealthIcon(CharacterRegistry.fetchCharacterData(_song.characters[0]).healthIcon.id);
		rightIcon = new HealthIcon(CharacterRegistry.fetchCharacterData(_song.characters[1]).healthIcon.id);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);
		leftIcon.setGraphicSize(0, 65);
		rightIcon.setGraphicSize(0, 65);
		add(leftIcon);
		add(rightIcon);



		curRenderedSustains = nextRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = nextRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedEvents = nextRenderedEvents = new FlxTypedSpriteGroup<Note>(Math.floor(-1 * GRID_SIZE) + GRID_SIZE, 0);
		curRenderedNoteType = new FlxTypedGroup<FlxText>();
		FlxG.mouse.visible = true;

        currentSongName = _song.song.toLowerCase();
		loadSong();
		reloadGridLayer();
		Conductor.bpm = _song.bpm;
		Conductor.mapBPMChanges(_song);
		if(curSection >= _song.notes.length) curSection = _song.notes.length - 1;

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * 9), 4);
		add(strumLine);

		leftIcon.setPosition(GRID_SIZE + 10, strumLine.y - 100);
		rightIcon.setPosition(GRID_SIZE * 5.2, strumLine.y - 100);

        camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Event", label: 'Event'},
			{name: "Charting", label: 'Charting'},
		];
        UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(300, 400);
		UI_box.x = 640 + GRID_SIZE / 2;
		UI_box.y = 25;
		UI_box.scrollFactor.set();
        add(UI_box);

		addSongUI();
		addNoteUI();
		addSectionUI();
		addEventsUI();
		addChartingUI();
		updateHeads();
		updateWaveform();

        add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedEvents);
		add(curRenderedNoteType);
		add(nextRenderedSustains);
		add(nextRenderedNotes);
		add(nextRenderedEvents);

        if(lastSong != currentSongName) {
			changeSection();
		}
		lastSong = currentSongName;

		zoomTxt = new FlxText(10, 10, 0, "Zoom: 1 / 1", 16);
		zoomTxt.scrollFactor.set();
		add(zoomTxt);

		updateGrid();

		

		Paths.clearUnusedMemory();
    }

	var UI_songTitle:FlxUIInputText;
	var noteSkinInputText:FlxUIInputText;
	var noteSplashesInputText:FlxUIInputText;
    function addSongUI():Void
    {
        UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		blockPressWhileTypingOn.push(UI_songTitle);

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
		};

        var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveJson(getSongString("\t"), PlayState.curDifficulty);
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + 90, saveButton.y, "Reload Audio", function()
		{
			currentSongName = UI_songTitle.text.toLowerCase();
			loadSong();
			updateWaveform();
		});

        var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			loadJson(_song.song);
		});

        var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'Load Autosave', function()
        {
            PlayState.SONG = Song.checkSong(Song.parseJson('', FlxG.save.data.autosave));
            FlxG.resetState();
        });

        var saveEvents:FlxButton = new FlxButton(110, reloadSongJson.y, 'Save Meta', function ()
        {
            saveEvents();
        });

        var clear_events:FlxButton = new FlxButton(320, 310, 'Clear events', function()
		{
            for (sec in 0..._song.notes.length) 
                _song.notes[sec].sectionEvents = [];
            updateGrid();
		});
		clear_events.color = FlxColor.RED;
		clear_events.label.color = FlxColor.WHITE;

        var clear_notes:FlxButton = new FlxButton(320, clear_events.y + 30, 'Clear notes', function()
		{
            for (sec in 0..._song.notes.length) 
                _song.notes[sec].sectionNotes = [];
            updateGrid();
		});
		clear_notes.color = FlxColor.RED;
		clear_notes.label.color = FlxColor.WHITE;

        var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 70, 1, 1, 1, 400, 3);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		blockPressWhileTypingOnStepper.push(stepperBPM);

        var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, stepperBPM.y + 35, 0.1, 1, 0.1, 10, 2);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		blockPressWhileTypingOnStepper.push(stepperSpeed);

        var characters:Array<String> = CharacterRegistry.listCharacterIds();
        var player1DropDown = new FlxUIDropDownMenu(10, stepperSpeed.y + 45, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
        {
            _song.characters[0] = characters[Std.parseInt(character)];
            updateHeads();
        });
        player1DropDown.selectedLabel = _song.characters[0];
        blockPressWhileScrolling.push(player1DropDown);

        var player2DropDown = new FlxUIDropDownMenu(player1DropDown.x, player1DropDown.y + 40, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
        {
            _song.characters[1] = characters[Std.parseInt(character)];
            updateHeads();
        });
        player2DropDown.selectedLabel = _song.characters[1];
        blockPressWhileScrolling.push(player2DropDown);

        var player3DropDown = new FlxUIDropDownMenu(player1DropDown.x, player2DropDown.y + 40, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
        {
            _song.characters[2] = characters[Std.parseInt(character)];
            updateHeads();
        });
        player3DropDown.selectedLabel = _song.characters[2];
        blockPressWhileScrolling.push(player3DropDown);

        var stages:Array<String> = StageRegistry.instance.listEntryIds();
        var stageDropDown = new FlxUIDropDownMenu(player1DropDown.x + 140, player1DropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true), function(character:String)
        {
            _song.stage = stages[Std.parseInt(character)];
        });
        stageDropDown.selectedLabel = _song.stage;
        blockPressWhileScrolling.push(stageDropDown);

        var assetModifier:Array<String> = CoolUtil.returnAssetsLibrary('UI/default');
        var assetModifierDropDown = new FlxUIDropDownMenu(stageDropDown.x, player1DropDown.y + 40, FlxUIDropDownMenu.makeStrIdLabelArray(assetModifier, true), function(character:String)
        {
            _song.assetModifier = assetModifier[Std.parseInt(character)];
			updateGrid();
        });
        assetModifierDropDown.selectedLabel = _song.assetModifier;
        blockPressWhileScrolling.push(assetModifierDropDown);

		var skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : "";
		noteSkinInputText = new FlxUIInputText(player3DropDown.x, player3DropDown.y + 50, 130, skin, 8);
		blockPressWhileTypingOn.push(noteSkinInputText);

		noteSplashesInputText = new FlxUIInputText(noteSkinInputText.x + 140, noteSkinInputText.y, 130, _song.splashSkin, 8);
		blockPressWhileTypingOn.push(noteSplashesInputText);

		var reloadNotesButton:FlxButton = new FlxButton(noteSkinInputText.x, noteSkinInputText.y + 50, 'Change Skins', function() {
			_song.arrowSkin = noteSkinInputText.text;
			updateGrid();
		});

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(clear_events);
		tab_group_song.add(clear_notes);
		tab_group_song.add(saveButton);
		tab_group_song.add(saveEvents);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(new FlxText(stepperBPM.x, stepperBPM.y - 15, 0, 'Song BPM:'));
		tab_group_song.add(new FlxText(stepperBPM.x + 100, stepperBPM.y - 15, 0, 'Song Offset:'));
		tab_group_song.add(new FlxText(stepperSpeed.x, stepperSpeed.y - 15, 0, 'Song Speed:'));
		tab_group_song.add(new FlxText(player2DropDown.x, player2DropDown.y - 15, 0, 'Opponent:'));
		tab_group_song.add(new FlxText(player3DropDown.x, player3DropDown.y - 15, 0, 'Girlfriend:'));
		tab_group_song.add(new FlxText(player1DropDown.x, player1DropDown.y - 15, 0, 'Boyfriend:'));
		tab_group_song.add(new FlxText(stageDropDown.x, stageDropDown.y - 15, 0, 'Stage:'));
        tab_group_song.add(new FlxText(assetModifierDropDown.x, assetModifierDropDown.y - 15, 0, 'Asset Modifier:'));
		tab_group_song.add(new FlxText(noteSkinInputText.x, noteSkinInputText.y - 15, 0, 'Note Skin:'));
		tab_group_song.add(new FlxText(noteSplashesInputText.x, noteSplashesInputText.y - 15, 0, 'Note Splashes Skin:'));
		tab_group_song.add(noteSkinInputText);
		tab_group_song.add(noteSplashesInputText);
		tab_group_song.add(reloadNotesButton);
		tab_group_song.add(player3DropDown);
		tab_group_song.add(player2DropDown);
        tab_group_song.add(assetModifierDropDown);
		tab_group_song.add(stageDropDown);
		tab_group_song.add(player1DropDown);

		UI_box.addGroup(tab_group_song);
        FlxG.camera.follow(camPos, LOCKON, 999);
    }

    var stepperBeats:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var sectionNoteTypesDropDown:FlxUIDropDownMenu;

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;

	function addSectionUI():Void
	{
        var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		check_mustHitSection = new FlxUICheckBox(10, 15, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = _song.notes[curSection].mustHitSection;

		//Stolen From Maru :/
		var setTypesLeft:FlxUICheckBox = new FlxUICheckBox(check_mustHitSection.x + 120, check_mustHitSection.y, null, null, "Left Side");
		var setTypesRight:FlxUICheckBox = new FlxUICheckBox(setTypesLeft.x + 100, setTypesLeft.y, null, null, "Right Side");
		setTypesLeft.checked = setTypesRight.checked = true;
		var setSectionNoteTypes:FlxButton = new FlxButton(10, setTypesLeft.y + 40, "Set Types", function() {
			for (note in _song.notes[curSection].sectionNotes) 
			{
				var sideLength = 4 - 1;
				if ((note[1] <= sideLength && setTypesLeft.checked) || (note[1] > sideLength && setTypesRight.checked)) 
				{
					note[3] = sectionNoteTypesDropDown.selectedLabel;
				    updateGrid();
				}
			}
		});
		sectionNoteTypesDropDown = new FlxUIDropDownMenu(setSectionNoteTypes.x + 100, setSectionNoteTypes.y, FlxUIDropDownMenu.makeStrIdLabelArray(NoteTypeRegistry.instance.listEntryIds().copy(), true));
		sectionNoteTypesDropDown.selectedLabel = 'default';
		blockPressWhileScrolling.push(sectionNoteTypesDropDown);

		stepperBeats = new FlxUINumericStepper(10, 100, 1, 4, 1, 7, 2);
		stepperBeats.value = getSectionBeats();
		stepperBeats.name = 'section_beats';
		blockPressWhileTypingOnStepper.push(stepperBeats);

        check_changeBPM = new FlxUICheckBox(10, stepperBeats.y + 30, null, null, 'Change BPM', 100);
		check_changeBPM.checked = _song.notes[curSection].changeBPM;
		check_changeBPM.name = 'check_changeBPM';

		stepperSectionBPM = new FlxUINumericStepper(10, check_changeBPM.y + 20, 1, Conductor.bpm, 0, 999, 1);
		if(check_changeBPM.checked) 
			stepperSectionBPM.value = _song.notes[curSection].bpm;
		else 
            stepperSectionBPM.value = Conductor.bpm;
        
		stepperSectionBPM.name = 'section_bpm';
		blockPressWhileTypingOnStepper.push(stepperSectionBPM);

        var check_eventsSec:FlxUICheckBox = null;
		var check_notesSec:FlxUICheckBox = null;
		var copyButton:FlxButton = new FlxButton(10, 190, "Copy Section", function()
		{
			notesCopied = [];
			sectionToCopy = curSection;
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSection].sectionNotes[i];
				notesCopied.push(note);
			}

			for (i in 0..._song.notes[curSection].sectionEvents.length)
			{
				var note:Array<Dynamic> = _song.notes[curSection].sectionEvents[i];
				notesCopied.push(note);
			}
		});

        var pasteButton:FlxButton = new FlxButton(copyButton.x + 100, copyButton.y, "Paste Section", function()
		{ 
			if(notesCopied == null || notesCopied.length < 1) return;

			var addToTime:Float = Conductor.stepCrochet * (getSectionBeats() * 4 * (curSection - sectionToCopy));
			
			for (note in notesCopied)
			{
				var newStrumTime:Float = note[0] + addToTime;
				if(note[1] < 0)
				{
					if(check_eventsSec.checked)
					{
                        var event:Array<Dynamic> = [newStrumTime, note[1], cast(note[2], Array<Dynamic>).copy()];
						_song.notes[curSection].sectionEvents.push(event);
					}
				}
				else
				{
					if(check_notesSec.checked)
					{
						var copiedNote:Array<Dynamic>  = [newStrumTime, note[1], note[2], note[3]];
						_song.notes[curSection].sectionNotes.push(copiedNote);
					}
				}
			}
			updateGrid();
		});

        var clearSectionButton:FlxButton = new FlxButton(pasteButton.x + 100, pasteButton.y, "Clear", function()
        {
            if(check_notesSec.checked)
            {
                _song.notes[curSection].sectionNotes = [];
				updateNoteUI();
            }
    
            if(check_eventsSec.checked)
            {
                _song.notes[curSection].sectionEvents = [];
				eventID = 0;
            }
            updateGrid();
        });
        clearSectionButton.color = FlxColor.RED;
        clearSectionButton.label.color = FlxColor.WHITE;
            
        check_notesSec = new FlxUICheckBox(10, clearSectionButton.y + 25, null, null, "Notes", 100);
        check_notesSec.checked = true;
        check_eventsSec = new FlxUICheckBox(check_notesSec.x + 100, check_notesSec.y, null, null, "Events", 100);
        check_eventsSec.checked = true;
    
        var swapSection:FlxButton = new FlxButton(10, check_notesSec.y + 40, "Swap section", function()
        {
            for (i in 0..._song.notes[curSection].sectionNotes.length)
            {
                var note:Array<Dynamic> = _song.notes[curSection].sectionNotes[i];
                note[1] = (note[1] + 4) % 8;
                _song.notes[curSection].sectionNotes[i] = note;
            }
            updateGrid();
        });
		
        var stepperCopy:FlxUINumericStepper = null;
        var copyLastButton:FlxButton = new FlxButton(10, swapSection.y + 30, "Copy last section", function()
        {
            var value:Int = Std.int(stepperCopy.value);
            if(value == 0) return;
    
            var daSec = FlxMath.maxInt(curSection, value);
    
            for (note in _song.notes[daSec - value].sectionNotes)
            {
                var strum = note[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);
    
                var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
                _song.notes[daSec].sectionNotes.push(copiedNote);
            }
    
            for (note in _song.notes[daSec - value].sectionEvents)
            {
                var strum = note[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);
                var event:Array<Dynamic> = [strum, note[1], cast(note[2], Array<Dynamic>).copy()];
                _song.notes[daSec].sectionEvents.push(event);
            }
            updateGrid();
        });
        copyLastButton.setGraphicSize(80, 30);
        copyLastButton.updateHitbox();
            
        stepperCopy = new FlxUINumericStepper(copyLastButton.x + 100, copyLastButton.y, 1, 1, -999, 999, 0);
        blockPressWhileTypingOnStepper.push(stepperCopy);
    
        var duetButton:FlxButton = new FlxButton(10, copyLastButton.y + 45, "Duet Notes", function()
        {
            var duetNotes:Array<Array<Dynamic>> = [];
            for (note in _song.notes[curSection].sectionNotes)
            {
                var boob = note[1];
                if (boob>3)
                    boob -= 4;
                else
                    boob += 4;
                    
    
                var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
                duetNotes.push(copiedNote);
            }
    
            for (i in duetNotes)
                _song.notes[curSection].sectionNotes.push(i);
    
            updateGrid();
        });

        var mirrorButton:FlxButton = new FlxButton(duetButton.x + 100, duetButton.y, "Mirror Notes", function()
        {
            var duetNotes:Array<Array<Dynamic>> = [];
            for (note in _song.notes[curSection].sectionNotes)
            {
                var boob = note[1]%4;
                boob = 3 - boob;
                if (note[1] > 3) boob += 4;
    
                note[1] = boob;
                var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
            }
            updateGrid();
        });

		tab_group_section.add(new FlxText(stepperBeats.x, stepperBeats.y - 15, 0, 'Beats per Section:'));
		tab_group_section.add(stepperBeats);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(pasteButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(check_notesSec);
		tab_group_section.add(check_eventsSec);
		tab_group_section.add(swapSection);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(copyLastButton);
		tab_group_section.add(duetButton);
		tab_group_section.add(setTypesLeft);
		tab_group_section.add(setTypesRight);
		tab_group_section.add(setSectionNoteTypes);
		tab_group_section.add(new FlxText(sectionNoteTypesDropDown.x, sectionNoteTypesDropDown.y - 15, 0, 'Type Sections:'));
		tab_group_section.add(sectionNoteTypesDropDown);
		UI_box.addGroup(tab_group_section);
    }

    
	var stepperSusLength:FlxUINumericStepper;
	var strumTimeInputText:FlxUIInputText; //I wanted to use a stepper but we can't scale these as far as i know :(
	var noteTypeDropDown:FlxUIDropDownMenu;
	var currentType:String = 'default'; 
	function addNoteUI():Void
	{
        var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 25, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 64);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';
		blockPressWhileTypingOnStepper.push(stepperSusLength);

		strumTimeInputText = new FlxUIInputText(10, 65, 180, "0");
		tab_group_note.add(strumTimeInputText);
		blockPressWhileTypingOn.push(strumTimeInputText);

		var noteType:Array<String> = NoteTypeRegistry.instance.listEntryIds().copy();
		noteTypeDropDown = new FlxUIDropDownMenu(10, 105, FlxUIDropDownMenu.makeStrIdLabelArray(noteType, true), function(character:String)
		{
			currentType = noteType[Std.parseInt(character)];
			if(curSelectedNote != null) {
				curSelectedNote[3] = currentType;
				updateGrid();
			}
		});
		noteTypeDropDown.selectedLabel = 'default';
		blockPressWhileScrolling.push(noteTypeDropDown);

		tab_group_note.add(new FlxText(10, 10, 0, 'Sustain length:'));
		tab_group_note.add(new FlxText(10, 50, 0, 'Strum time (in miliseconds):'));
		tab_group_note.add(new FlxText(10, 90, 0, 'Note type:'));
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(strumTimeInputText);
		tab_group_note.add(noteTypeDropDown);

		UI_box.addGroup(tab_group_note);
    }

    var eventsDropDown:FlxUIDropDownMenu;
	var eventDescription:FlxText;
	public var eventValueTab:EventTab = null;
    var initEvent:String = "NULL_EVENT";
	public static var curEventDatas:Array<{name:String, values:Array<Dynamic>}> = [];
	public static var curEventNames:Array<String> = [];
	var eventID:Int = 0;
	public var selectedEvents:Array<Dynamic> = [];
	function updateCurData(event:String) {
		curEventDatas[eventID] = {
			curEventDatas[eventID] = {
				name: event,
				values: eventValueTab == null ? EventsHandler.getEvents(event).values.copy() : eventValueTab.getValues().copy()
			}
		}
	}

	public function setCurEvent(event:String) {
		curEventNames[eventID] = event;
		updateCurData(event);
		updateEventTxt();
	}

    function setEventTab(newEvent:String, ?values:Array<Dynamic>) {
		var eventData = EventsHandler.getEvents(newEvent);
		var _defValues = eventData.values.copy();
		eventDescription.text = eventData.returnDescription();
		eventValueTab.createUI(_defValues);

		if (values != null) {
			eventsDropDown.selectedLabel = newEvent;
			eventValueTab.setValues(values);
		}
		else {
			setCurEvent(newEvent);
			setEventData(_defValues.copy(), newEvent);
		}
	}

    public function setEventData(newData:Array<Dynamic>, name:String) {
		if(curSelectedEvent != null && curSelectedEvent.length > 0)
		{
			curSelectedEvent[eventID][0] = name;
			curSelectedEvent[eventID][1] = convertEventValues(newData.copy());
			updateGrid();
		}
    }
    
    public function updateEventTxt() {
		eventListTxt.text = "[ " +
		(eventID + 1) + " / " +
		(curEventNames.length) + " ] " +
		(curEventNames[eventID] ?? "NULL_EVENT");
	}

    function updateEvent(id:Int = 0, newValue:Dynamic) {
		if(curSelectedEvent != null && curSelectedEvent.length > 0)
		{
			var curEvent = curSelectedEvent[0][eventID];
			var values = curEvent[1].copy();
			values[id] = newValue;
			curEvent[1] = values;
			updateGrid();
		}
    }

    public function convertEventValues(values:Array<Dynamic>) {
		for (i in 0...values.length) {
			switch (Type.typeof(values[i])) {
				case TClass(Array): values[i] = values[i].copy()[0];
				default:
			}
		}
		return values;
	}

	function pushEvent(data:Array<Dynamic>) 
	{
		if(curSelectedEvent != null && curSelectedEvent.length > 0)
		{
			_song.notes[curSection].sectionEvents.push(data);
			curSelectedEvent[1].push(data);
			updateGrid();
		}
	}

	var eventListTxt:FlxText;
	var eventLeft:FlxUIButton;
	var eventAdd:FlxUIButton;
	var eventRemove:FlxUIButton;
	var eventRight:FlxUIButton;
	function addEventsUI():Void
	{
        curEventDatas.clear();
		curEventNames.clear();

        var tab_group_event = new FlxUI(null, UI_box);
		tab_group_event.name = 'Event';
        
        eventListTxt = new FlxText(110, 10, 0, "", 12);
		eventListTxt.antialiasing = false;
		eventListTxt.alignment = RIGHT;

		eventLeft = new FlxUIButton(10,10, "<", function () {
			var id:Int = eventID;
			updateCurData(curEventNames[id]);
			eventID = FlxMath.wrap(id - 1, 0, curEventDatas.length - 1);
			if (eventID != id) {
				setEventTab(curEventNames[eventID], curEventDatas[eventID].values);
				updateEventTxt();
			}
		});

		eventRight = new FlxUIButton(eventLeft.x + (25*3),eventLeft.y, ">", function () {
			var id:Int = eventID;
			updateCurData(curEventNames[id]);
			eventID = FlxMath.wrap(id + 1, 0, curEventDatas.length - 1);
			if (eventID != id) {
				setEventTab(curEventNames[eventID], curEventDatas[eventID].values);
				updateEventTxt();
			}
		});

        eventAdd = new FlxUIButton(eventLeft.x + 25,eventLeft.y, "+", function () {
			var e:String = eventsDropDown.selectedLabel;
			var d = eventValueTab == null ? EventsHandler.getEvents(e).values.copy() : eventValueTab.getValues().copy();
			
			curEventNames.push(e);
			curEventDatas.push({
				name: e,
				values: d
			});

			pushEvent([0, e, d]);
			eventID = curEventDatas.length - 1;
			updateEventTxt();
		});
		eventAdd.color = FlxColor.LIME;
		eventAdd.label.color = FlxColor.WHITE;

        eventRemove = new FlxUIButton(eventLeft.x + (25*2),eventLeft.y, "-", function () {
			if (curEventDatas.length > 1) {
				curEventDatas.remove(curEventDatas[eventID]);
				curEventNames.remove(curEventNames[eventID]);
				
				if (curSelectedEvent != null && curSelectedEvent.length > 0 && curSelectedEvent[1].length > 1) 
				{
					curSelectedEvent[1].remove(curSelectedEvent[1][eventID]);
					_song.notes[curSection].sectionEvents.remove(curSelectedEvent[1][eventID]);
					curSelectedEvent = null;
				}
					
				eventID = curEventDatas.length - 1;
				updateEventTxt();
			}
		});
		eventRemove.color = FlxColor.RED;
		eventRemove.label.color = FlxColor.WHITE;

        var types:Array<String> = EventsHandler.eventsCache.keys().array().copy();
		eventsDropDown = new FlxUIDropDownMenu(10, 50, FlxUIDropDownMenu.makeStrIdLabelArray(types, true), function(type:String) {
			var newEvent = types[Std.parseInt(type)];
			if (curEventDatas[eventID].name != newEvent) {
				setEventTab(newEvent);
			}
		});

		eventDescription = new FlxText(eventsDropDown.x,eventsDropDown.y + 25, 125, "Lorem ipsum dolor sit amet, consectetur adipiscing elit.");

        initEvent = types[0];
        if (initEvent != null) {
            setCurEvent(initEvent);
            eventsDropDown.selectedLabel = initEvent;
            eventDescription.text = EventsHandler.getEvents(initEvent).returnDescription();
        }
        
        eventValueTab = new EventTab(150, 50, curEventDatas[eventID].values);
        eventValueTab.updateFunc = (id:Int, value:Dynamic) -> {
            updateEvent(id, value);
        }
        updateEventTxt();
      
        for (i in [eventLeft, eventAdd, eventRemove, eventRight]) {
			tab_group_event.add(i);
			i.resize(20,20);
		}
		tab_group_event.add(eventListTxt);
        tab_group_event.add(eventDescription);
        tab_group_event.add(eventValueTab);
        tab_group_event.add(new FlxText(eventsDropDown.x, eventsDropDown.y - 15, 0, 'Event:'));
		tab_group_event.add(eventsDropDown);
		UI_box.addGroup(tab_group_event);
    }

	var instVolume:FlxUINumericStepper;
	var voicesVolume:FlxUINumericStepper;
	var voicesOppVolume:FlxUINumericStepper;
    var check_mute_inst:FlxUICheckBox = null;
	var check_mute_vocals:FlxUICheckBox = null;
	var check_mute_vocals_opponent:FlxUICheckBox = null;
	var playSoundBf:FlxUICheckBox = null;
	var playSoundDad:FlxUICheckBox = null;
    var sliderRate:FlxUISlider;
	function addChartingUI() 
    {
        var tab_group_chart = new FlxUI(null, UI_box);
		tab_group_chart.name = 'Charting';

		#if desktop
		if (FlxG.save.data.chart_waveformInst == null) FlxG.save.data.chart_waveformInst = false;
		if (FlxG.save.data.chart_waveformVoices == null) FlxG.save.data.chart_waveformVoices = false;
		if (FlxG.save.data.chart_waveformOppVoices == null) FlxG.save.data.chart_waveformOppVoices = false;

		var waveformUseInstrumental:FlxUICheckBox = null;
		var waveformUseVoices:FlxUICheckBox = null;
		var waveformUseOppVoices:FlxUICheckBox = null;

		waveformUseInstrumental = new FlxUICheckBox(10, 90, null, null, "Waveform\n(Instrumental)", 85);
		waveformUseInstrumental.checked = FlxG.save.data.chart_waveformInst;
		waveformUseInstrumental.callback = function()
		{
			waveformUseVoices.checked = false;
			waveformUseOppVoices.checked = false;
			FlxG.save.data.chart_waveformVoices = false;
			FlxG.save.data.chart_waveformOppVoices = false;
			FlxG.save.data.chart_waveformInst = waveformUseInstrumental.checked;
			updateWaveform();
		};

		waveformUseVoices = new FlxUICheckBox(waveformUseInstrumental.x + 100, waveformUseInstrumental.y, null, null, "Waveform\n(Main Vocals)", 85);
		waveformUseVoices.checked = FlxG.save.data.chart_waveformVoices && !waveformUseInstrumental.checked;
		waveformUseVoices.callback = function()
		{
			waveformUseInstrumental.checked = false;
			waveformUseOppVoices.checked = false;
			FlxG.save.data.chart_waveformInst = false;
			FlxG.save.data.chart_waveformOppVoices = false;
			FlxG.save.data.chart_waveformVoices = waveformUseVoices.checked;
			updateWaveform();
		};

		waveformUseOppVoices = new FlxUICheckBox(waveformUseInstrumental.x + 200, waveformUseInstrumental.y, null, null, "Waveform\n(Opp. Vocals)", 85);
		waveformUseOppVoices.checked = FlxG.save.data.chart_waveformOppVoices && !waveformUseVoices.checked;
		waveformUseOppVoices.callback = function()
		{
			waveformUseInstrumental.checked = false;
			waveformUseVoices.checked = false;
			FlxG.save.data.chart_waveformInst = false;
			FlxG.save.data.chart_waveformVoices = false;
			FlxG.save.data.chart_waveformOppVoices = waveformUseOppVoices.checked;
			updateWaveform();
		};
		#end

		check_mute_inst = new FlxUICheckBox(10, 280, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = instVolume.value;
			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};
	
		check_mute_vocals = new FlxUICheckBox(check_mute_inst.x, check_mute_inst.y + 30, null, null, "Mute Main Vocals (in editor)", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.callback = function()
		{
			var vol:Float = voicesVolume.value;
			if (check_mute_vocals.checked)
				vol = 0;

			if(vocals != null) vocals.volume = vol;
		};
		check_mute_vocals_opponent = new FlxUICheckBox(check_mute_vocals.x + 120, check_mute_vocals.y, null, null, "Mute Opp. Vocals (in editor)", 100);
		check_mute_vocals_opponent.checked = false;
		check_mute_vocals_opponent.callback = function()
		{
			var vol:Float = voicesOppVolume.value;
			if (check_mute_vocals_opponent.checked)
				vol = 0;

			if(opponentVocals != null) opponentVocals.volume = vol;
		};

		playSoundBf = new FlxUICheckBox(check_mute_inst.x, check_mute_vocals.y + 30, null, null, 'Play Sound (Boyfriend notes)', 100,
			function() {
				FlxG.save.data.chart_playSoundBf = playSoundBf.checked;
			}
		);
		if (FlxG.save.data.chart_playSoundBf == null) FlxG.save.data.chart_playSoundBf = false;
		playSoundBf.checked = FlxG.save.data.chart_playSoundBf;

		playSoundDad = new FlxUICheckBox(check_mute_inst.x + 120, playSoundBf.y, null, null, 'Play Sound (Opponent notes)', 100,
			function() {
				FlxG.save.data.chart_playSoundDad = playSoundDad.checked;
			}
		);
		if (FlxG.save.data.chart_playSoundDad == null) FlxG.save.data.chart_playSoundDad = false;
		playSoundDad.checked = FlxG.save.data.chart_playSoundDad;

		instVolume = new FlxUINumericStepper(10, 15, 0.1, 1, 0, 1, 1);
		instVolume.value = FlxG.sound.music.volume;
		instVolume.name = 'inst_volume';
		blockPressWhileTypingOnStepper.push(instVolume);

		voicesVolume = new FlxUINumericStepper(instVolume.x + 100, instVolume.y, 0.1, 1, 0, 1, 1);
		voicesVolume.value = vocals.volume;
		voicesVolume.name = 'voices_volume';
		blockPressWhileTypingOnStepper.push(voicesVolume);

		voicesOppVolume = new FlxUINumericStepper(instVolume.x + 200, instVolume.y, 0.1, 1, 0, 1, 1);
		voicesOppVolume.value = vocals.volume;
		voicesOppVolume.name = 'voices_opp_volume';
		blockPressWhileTypingOnStepper.push(voicesOppVolume);
		
        sliderRate = new FlxUISlider(this, 'playbackSpeed', 120, 120, 0.5, 3, 150, null, 5, FlxColor.WHITE, FlxColor.BLACK);
		sliderRate.nameLabel.text = 'Playback Rate';
		tab_group_chart.add(sliderRate);

		tab_group_chart.add(new FlxText(instVolume.x, instVolume.y - 15, 0, 'Inst Volume'));
		tab_group_chart.add(new FlxText(voicesVolume.x, voicesVolume.y - 15, 0, 'Main Vocals'));
		tab_group_chart.add(new FlxText(voicesOppVolume.x, voicesOppVolume.y - 15, 0, 'Opp. Vocals'));
		#if desktop
		tab_group_chart.add(waveformUseInstrumental);
		tab_group_chart.add(waveformUseVoices);
		tab_group_chart.add(waveformUseOppVoices);
		#end
		tab_group_chart.add(instVolume);
		tab_group_chart.add(voicesVolume);
		tab_group_chart.add(voicesOppVolume);
		tab_group_chart.add(check_mute_inst);
		tab_group_chart.add(check_mute_vocals);
		tab_group_chart.add(check_mute_vocals_opponent);
		tab_group_chart.add(playSoundBf);
		tab_group_chart.add(playSoundDad);
		UI_box.addGroup(tab_group_chart);
    }

    function loadSong():Void
    {
        if(FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if(vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}
		if(opponentVocals != null)
		{
			opponentVocals.stop();
			opponentVocals.destroy();
		}
		var suffix:String = (_song.variation != null && _song.variation != '' && _song.variation != 'default') ? '-${_song.variation}' : '';
		var voiceList:Array<String> = CoolUtil.buildVoiceList(_song, suffix);

        vocals = opponentVocals = new FlxSound();
		if (_song.needsVoices && voiceList[0] != null && voiceList[1] != null)
		{
			vocals = FlxG.sound.load(voiceList[0]);
			opponentVocals = FlxG.sound.load(voiceList[1]);
		}

		vocals.autoDestroy = opponentVocals.autoDestroy = false;
		FlxG.sound.list.add(vocals);
		
		FlxG.sound.list.add(opponentVocals);

        generateSong();
		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;

		var curTime:Float = 0;
		if(_song.notes.length <= 1) //First load ever
		{
			trace('first load ever!!');
			while(curTime < FlxG.sound.music.length)
			{
				addSection();
				curTime += (60 / _song.bpm) * 4000;
			}
		}
    }

    function generateSong() 
    {
		FlxG.sound.playMusic(Paths.inst(currentSongName), 0.6/*, false*/);
		FlxG.sound.music.autoDestroy = false;
		if (instVolume != null) FlxG.sound.music.volume = instVolume.value;
		if (check_mute_inst != null && check_mute_inst.checked) FlxG.sound.music.volume = 0;

		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;
			if(vocals != null) {
				vocals.pause();
				vocals.time = 0;
			}
			if(opponentVocals != null) {
				opponentVocals.pause();
				opponentVocals.time = 0;
			}
			changeSection();
			curSection = 0;
			updateGrid();
			updateSectionUI();
			if(vocals != null) vocals.play();
			if(opponentVocals != null) opponentVocals.play();
		};
	}

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
    {
        if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':
					_song.notes[curSection].mustHitSection = check.checked;

					updateGrid();
					updateHeads();
				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
			}
		}
        else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
        {
            var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			//FlxG.log.add(wname);
			switch(wname)
			{
				case 'section_beats':
					_song.notes[curSection].sectionBeats = nums.value;
					reloadGridLayer();

				case 'song_speed':
					_song.speed = nums.value;

				case 'song_bpm':
					_song.bpm = nums.value;
					Conductor.mapBPMChanges(_song);
					Conductor.bpm = nums.value;
					stepperSusLength.stepSize = Math.ceil(Conductor.stepCrochet / 2);
					updateGrid();

				case 'note_susLength':
					if(curSelectedNote != null && curSelectedNote[2] != null) {
						curSelectedNote[2] = nums.value;
						updateGrid();
					}

				case 'section_bpm':
					_song.notes[curSection].bpm = nums.value;
					updateGrid();

				case 'inst_volume':
					FlxG.sound.music.volume = nums.value;
					if(check_mute_inst.checked) FlxG.sound.music.volume = 0;

				case 'voices_volume':
					vocals.volume = nums.value;
					if(check_mute_vocals.checked) vocals.volume = 0;

				case 'voices_opp_volume':
					opponentVocals.volume = nums.value;
					if(check_mute_vocals_opponent.checked) opponentVocals.volume = 0;
			}
        }
        else if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) 
        {
            if(curSelectedNote != null)
			{
				if(sender == strumTimeInputText) {
					var value:Float = Std.parseFloat(strumTimeInputText.text);
					if(Math.isNaN(value)) value = 0;
					curSelectedNote[0] = value;
					updateGrid();
				}
			}
        }
        else if (id == FlxUISlider.CHANGE_EVENT && (sender is FlxUISlider))
        {
            switch (sender)
			{
				case 'playbackSpeed':
					playbackSpeed = #if FLX_PITCH Std.int(sliderRate.value) #else 1.0 #end;
			}
        }
    }

    var updatedSection:Bool = false;

	function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection + add)
		{
			if(_song.notes[i] != null)
			{
				if (_song.notes[i].changeBPM)
				{
					daBPM = _song.notes[i].bpm;
				}
				daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}

    var lastConductorPos:Float;
	var colorSine:Float = 0;
	override function update(elapsed:Float)
	{
        super.update(elapsed);

        curStep = recalculateSteps();

		if(FlxG.sound.music.time < 0) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if(FlxG.sound.music.time > FlxG.sound.music.length) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = UI_songTitle.text;

		strumLineUpdateY();

		leftIcon.y = rightIcon.y = strumLine.y - 100;

        FlxG.mouse.visible = true;//cause reasons. trust me
		camPos.y = strumLine.y;
        if (Math.ceil(strumLine.y) >= gridBG.height)
		{
			if (_song.notes[curSection + 1] == null)
				addSection();
			changeSection(curSection + 1, false);
		}
		else if(strumLine.y < -10)
			changeSection(curSection - 1, false);


        if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
		{
			dummyArrow.visible = true;
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
			{
				var gridmult = GRID_SIZE / (quantization / 16);
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridmult) * gridmult;
			}
		} else {
			dummyArrow.visible = false;
		}

        if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEachAlive(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL)
							selectNote(note);
						else
							deleteNote(note);
					}
				});
			}
			else if (FlxG.mouse.overlaps(curRenderedEvents))
			{
				curRenderedEvents.forEachAlive(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL)
							selectEvent(note);
						else
							deleteEvent(note);
					}
				});
			}
			else
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
				{
					FlxG.log.add('added note');
					addNote();
				}
			}
		}

        
		var blockInput:Bool = false;

		for (i in 0...blockPressWhileTypingOn.length) {
			if(blockPressWhileTypingOn[i].hasFocus) {
				Init.toggleVolumeKeys(false);
				blockInput = true;
				break;
			}
		}

		if(!blockInput) {
			for (i in 0...blockPressWhileTypingOnStepper.length) {
				@:privateAccess
				var leText:FlxUIInputText = cast (blockPressWhileTypingOnStepper[i].text_field, FlxUIInputText);
				if(leText.hasFocus) {
					Init.toggleVolumeKeys(false);
					blockInput = true;
					break;
				}
			}
		}

		if(!blockInput) {
			Init.toggleVolumeKeys(true);
			for (i in 0...blockPressWhileScrolling.length) {
				if(blockPressWhileScrolling[i].dropPanel.visible) {
					blockInput = true;
					break;
				}
			}
		}

        if (!blockInput)
        {
            if (FlxG.keys.justPressed.ENTER)
			{
				autosaveSong();
				FlxG.mouse.visible = false;
				PlayState.SONG = _song;
				PlayState.isChartingMode = true;
				FlxG.sound.music.stop();
				if(vocals != null) vocals.stop();
				if(opponentVocals != null) opponentVocals.stop();
				Main.switchState(new PlayState());
			}

            if(curSelectedNote != null) {
				if (FlxG.keys.justPressed.E || FlxG.keys.justPressed.Q)
					changeNoteSustain(FlxG.keys.justPressed.Q ? -Conductor.stepCrochet : Conductor.stepCrochet);
			}

            if(FlxG.keys.justPressed.Z && curZoom > 0 && !FlxG.keys.pressed.CONTROL) {
				--curZoom;
				updateZoom();
			}
			if(FlxG.keys.justPressed.X && curZoom < zoomList.length-1) {
				curZoom++;
				updateZoom();
			}

            if (FlxG.keys.justPressed.TAB)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					UI_box.selected_tab -= 1;
					if (UI_box.selected_tab < 0)
						UI_box.selected_tab = 2;
				}
				else
				{
					UI_box.selected_tab += 1;
					if (UI_box.selected_tab >= 3)
						UI_box.selected_tab = 0;
				}
			}

            if (FlxG.keys.justPressed.SPACE)
			{
				if(vocals != null) vocals.play();
				if(opponentVocals != null) opponentVocals.play();
				pauseAndSetVocalsTime();
				if (!FlxG.sound.music.playing)
				{
					FlxG.sound.music.play();
					if(vocals != null) vocals.play();
					if(opponentVocals != null) opponentVocals.play();
				}
				else FlxG.sound.music.pause();
			}

            if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

            if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				FlxG.sound.music.pause();

				var holdingShift:Float = 1;
				if (FlxG.keys.pressed.CONTROL) holdingShift = 0.25;
				else if (FlxG.keys.pressed.SHIFT) holdingShift = 4;

				var daTime:Float = 700 * FlxG.elapsed * holdingShift;

				FlxG.sound.music.time += daTime * (FlxG.keys.pressed.W ? -1 : 1);

				pauseAndSetVocalsTime();
			}

            var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;

			if (FlxG.keys.justPressed.D)
				changeSection(curSection + shiftThing);
			if (FlxG.keys.justPressed.A) {
				if(curSection <= 0) 
					changeSection(_song.notes.length-1);
				else 
					changeSection(curSection - shiftThing);
			}
        } else if (FlxG.keys.justPressed.ENTER) {
			for (i in 0...blockPressWhileTypingOn.length) {
				if(blockPressWhileTypingOn[i].hasFocus) {
					blockPressWhileTypingOn[i].hasFocus = false;
				}
			}
		}

        var holdingShift = FlxG.keys.pressed.SHIFT;
		var holdingLB = FlxG.keys.pressed.LBRACKET;
		var holdingRB = FlxG.keys.pressed.RBRACKET;
		var pressedLB = FlxG.keys.justPressed.LBRACKET;
		var pressedRB = FlxG.keys.justPressed.RBRACKET;

		if (!holdingShift && pressedLB || holdingShift && holdingLB)
			playbackSpeed -= 0.01;
		if (!holdingShift && pressedRB || holdingShift && holdingRB)
			playbackSpeed += 0.01;
		if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB))
			playbackSpeed = 1;
		//

		if (playbackSpeed <= 0.5)
			playbackSpeed = 0.5;
		if (playbackSpeed >= 3)
			playbackSpeed = 3;

		FlxG.sound.music.pitch = playbackSpeed;
		vocals.pitch = playbackSpeed;
		opponentVocals.pitch = playbackSpeed;

        bpmTxt.text =
		Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2)) + " / " + Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2)) +
		"\nSection: " + curSection +
		"\n\nBeat: " + curBeat +
		"\n\nStep: " + curStep +
		"\n\nBeat Snap: " + quantization + "th";

        var playedSound:Array<Bool> = [false, false, false, false]; //Prevents ouchy GF sex sounds

		curRenderedEvents.forEachAlive(function(note:Note) {
			note.alpha = 1;
			if(curSelectedEvent != null && curSelectedEvent.length > 0) {
				if (curSelectedEvent[0] == note.strumTime)
				{
					colorSine += elapsed;
					var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
					note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999); //Alpha can't be 100% or the color won't be updated for some reason, guess i will die
				}
			}

			if(note.strumTime <= Conductor.songPosition) note.alpha = 0.4;
		});
		curRenderedNotes.forEachAlive(function(note:Note) {
			note.alpha = 1;
			if(curSelectedNote != null) {
				if (curSelectedNote[0] == note.strumTime && (curSelectedNote[2] != null && curSelectedNote[1] % PlayState.numberOfKeys == note.noteData))
				{
					colorSine += elapsed;
					var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
					note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999); //Alpha can't be 100% or the color won't be updated for some reason, guess i will die
				}
			}

			if(note.strumTime <= Conductor.songPosition) {
				note.alpha = 0.4;
				if(note.strumTime > lastConductorPos && FlxG.sound.music.playing && note.noteData > -1) {
					var data:Int = note.noteData % 4;
					var noteDataToCheck:Int = note.noteData;
					if(!playedSound[data]) {
						if(((playSoundBf.checked && note.lane == 1) || (playSoundDad.checked && note.lane == 0)))
						{
							var soundToPlay = "soundNoteTick";
							if(_song.characters[0] == 'gf') //Easter egg
								soundToPlay = 'GF_' + Std.string(data + 1);

							FlxG.sound.play(Paths.sound(soundToPlay), 0.6).pan = note.noteData < 4? -0.3 : 0.3; //would be coolio
							playedSound[data] = true;
						}

						data = note.noteData;
					}
				}
			}
		});
        lastConductorPos = Conductor.songPosition;
    }

    function pauseAndSetVocalsTime()
	{
		if(vocals != null)
		{
			vocals.pause();
			vocals.time = FlxG.sound.music.time;
		}
		
		if(opponentVocals != null)
		{
			opponentVocals.pause();
			opponentVocals.time = FlxG.sound.music.time;
		}
	}

	function updateZoom() {
		var daZoom:Float = zoomList[curZoom];
		var zoomThing:String = '1 / ' + daZoom;
		if(daZoom < 1) zoomThing = Math.round(1 / daZoom) + ' / 1';
		zoomTxt.text = 'Zoom: ' + zoomThing;
		reloadGridLayer();
	}

    var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;
	var columns:Int = 9;
	function reloadGridLayer() {
		gridLayer.clear();
		gridBG = FlxGridOverlay.create(1, 1, columns, Std.int(getSectionBeats() * 4 * zoomList[curZoom]));
		gridBG.antialiasing = false;
		gridBG.scale.set(GRID_SIZE, GRID_SIZE);
		gridBG.updateHitbox();

		#if desktop
		if(FlxG.save.data.chart_waveformInst || FlxG.save.data.chart_waveformVoices || FlxG.save.data.chart_waveformOppVoices) {
			updateWaveform();
		}
		#end

		var leHeight:Int = Std.int(gridBG.height);
		var foundNextSec:Bool = false;
		if(sectionStartTime(1) <= FlxG.sound.music.length)
		{
			nextGridBG = FlxGridOverlay.create(1, 1, columns, Std.int(getSectionBeats(curSection + 1) * 4 * zoomList[curZoom]));
			nextGridBG.antialiasing = false;
			nextGridBG.scale.set(GRID_SIZE, GRID_SIZE);
			nextGridBG.updateHitbox();
			leHeight = Std.int(gridBG.height + nextGridBG.height);
			foundNextSec = true;
		}
		else nextGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		nextGridBG.y = gridBG.height;
		
		gridLayer.add(nextGridBG);
		gridLayer.add(gridBG);

		if(foundNextSec)
		{
			var gridBlack:FlxSprite = new FlxSprite(0, gridBG.height).makeGraphic(1, 1, FlxColor.BLACK);
			gridBlack.setGraphicSize(Std.int(GRID_SIZE * 9), Std.int(nextGridBG.height));
			gridBlack.updateHitbox();
			gridBlack.antialiasing = false;
			gridBlack.alpha = 0.4;
			gridLayer.add(gridBlack);
		}

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width - (GRID_SIZE * 4)).makeGraphic(1, 1, FlxColor.BLACK);
		gridBlackLine.setGraphicSize(2, leHeight);
		gridBlackLine.updateHitbox();
		gridBlackLine.antialiasing = false;
		gridLayer.add(gridBlackLine);

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(1, 1, FlxColor.BLACK);
		gridBlackLine.setGraphicSize(2, leHeight);
		gridBlackLine.updateHitbox();
		gridBlackLine.antialiasing = false;
		gridLayer.add(gridBlackLine);
		updateGrid();

		lastSecBeats = getSectionBeats();
		if(sectionStartTime(1) > FlxG.sound.music.length) lastSecBeatsNext = 0;
		else getSectionBeats(curSection + 1);
	}

    function strumLineUpdateY()
	{
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * 16)) / (getSectionBeats() / 4);
	}

	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];

	var lastWaveformHeight:Int = 0;
	function updateWaveform() {
		#if desktop
		if(waveformPrinted) {
			var width:Int = Std.int(GRID_SIZE * 8);
			var height:Int = Std.int(gridBG.height);
			if(lastWaveformHeight != height && waveformSprite.pixels != null)
			{
				waveformSprite.pixels.dispose();
				waveformSprite.pixels.disposeImage();
				waveformSprite.makeGraphic(width, height, 0x00FFFFFF);
				lastWaveformHeight = height;
			}
			waveformSprite.pixels.fillRect(new Rectangle(0, 0, width, height), 0x00FFFFFF);
		}
		waveformPrinted = false;

		if(!FlxG.save.data.chart_waveformInst && !FlxG.save.data.chart_waveformVoices && !FlxG.save.data.chart_waveformOppVoices) {
			//trace('Epic fail on the waveform lol');
			return;
		}

		wavData[0][0] = [];
		wavData[0][1] = [];
		wavData[1][0] = [];
		wavData[1][1] = [];

		var steps:Int = Math.round(getSectionBeats() * 4);
		var st:Float = sectionStartTime();
		var et:Float = st + (Conductor.stepCrochet * steps);

		var sound:FlxSound = FlxG.sound.music;
		if(FlxG.save.data.chart_waveformVoices)
			sound = vocals;
		else if(FlxG.save.data.chart_waveformOppVoices)
			sound = opponentVocals;
		
		if (sound != null && sound._sound != null && sound._sound.__buffer != null) {
			var bytes:Bytes = sound._sound.__buffer.data.toBytes();

			wavData = waveformData(
				sound._sound.__buffer,
				bytes,
				st,
				et,
				1,
				wavData,
				Std.int(gridBG.height)
			);
		}

		// Draws
		var gSize:Int = Std.int(GRID_SIZE * 8);
		var hSize:Int = Std.int(gSize / 2);
		var size:Float = 1;

		var leftLength:Int = (wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length);
		var rightLength:Int = (wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length);

		var length:Int = leftLength > rightLength ? leftLength : rightLength;

		for (index in 0...length)
		{
			var lmin:Float = FlxMath.bound(((index < wavData[0][0].length && index >= 0) ? wavData[0][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			var lmax:Float = FlxMath.bound(((index < wavData[0][1].length && index >= 0) ? wavData[0][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			var rmin:Float = FlxMath.bound(((index < wavData[1][0].length && index >= 0) ? wavData[1][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			var rmax:Float = FlxMath.bound(((index < wavData[1][1].length && index >= 0) ? wavData[1][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			waveformSprite.pixels.fillRect(new Rectangle(hSize - (lmin + rmin), index * size, (lmin + rmin) + (lmax + rmax), size), FlxColor.BLUE);
		}

		waveformPrinted = true;
		#end
	}

	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>, ?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null) return [[[0], [0]], [[0], [0]]];

		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;

		var index:Int = Std.int(time * khz);

		var samples:Float = ((endTime - time) * khz);

		if (steps == null) steps = 1280;

		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);

		var gotIndex:Int = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;

		var simpleSample:Bool = true;//samples > 17200;
		var v1:Bool = false;

		if (array == null) array = [[[0], [0]], [[0], [0]]];

		while (index < (bytes.length - 1)) {
			if (index >= 0) {
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2) byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0)
					if (sample > lmax) lmax = sample;
				else if (sample < 0)
					if (sample < lmin) lmin = sample;

				if (channels >= 2) {
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2) byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0) {
						if (sample > rmax) rmax = sample;
					} else if (sample < 0) {
						if (sample < rmin) rmin = sample;
					}
				}
			}

			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow) {
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;

				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;

				if (gotIndex > array[0][0].length) array[0][0].push(lRMin);
					else array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;

				if (gotIndex > array[0][1].length) array[0][1].push(lRMax);
					else array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;

				if (channels >= 2)
				{
					if (gotIndex > array[1][0].length) array[1][0].push(rRMin);
						else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(rRMax);
						else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else
				{
					if (gotIndex > array[1][0].length) array[1][0].push(lRMin);
						else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(lRMax);
						else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;
			if(gotIndex > steps) break;
		}

		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += Math.ceil(value);
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps(add:Float = 0):Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime + add) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		pauseAndSetVocalsTime();
		updateCurStep();

		updateGrid();
		updateSectionUI();
		updateWaveform();
	}

	private function addSection(sectionBeats:Float = 4):Void
	{
		var sec:SwagSection = {
			sectionNotes: [],
			sectionEvents: [],
			sectionBeats: sectionBeats,
			mustHitSection: true,
			bpm: _song.bpm,
			changeBPM: false
		};

		_song.notes.push(sec);
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		var waveformChanged:Bool = false;
		if (_song.notes[sec] != null)
		{
			Song.checkSection(_song.notes[sec]);
			curSection = sec;
			if (updateMusic)
			{
				FlxG.sound.music.pause();

				FlxG.sound.music.time = sectionStartTime();
				pauseAndSetVocalsTime();
				updateCurStep();
			}

			var blah1:Float = getSectionBeats();
			var blah2:Float = getSectionBeats(curSection + 1);
			if(sectionStartTime(1) > FlxG.sound.music.length) blah2 = 0;
	
			if(blah1 != lastSecBeats || blah2 != lastSecBeatsNext)
			{
				reloadGridLayer();
				waveformChanged = true;
			}
			else
			{
				updateGrid();
			}
			updateSectionUI();
		}
		else
		{
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		if(!waveformChanged) updateWaveform();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSection];

		stepperBeats.value = getSectionBeats();
		check_mustHitSection.checked = sec.mustHitSection;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

    function updateHeads():Void
    {
		var bf = CharacterRegistry.fetchCharacterData(_song.characters[0]).healthIcon.id;
		var dad = CharacterRegistry.fetchCharacterData(_song.characters[1]).healthIcon.id;
		rightIcon.char = _song.notes[curSection].mustHitSection ? dad : bf; 
		leftIcon.char = _song.notes[curSection].mustHitSection ? bf : dad; 
    }

    function updateNoteUI():Void
	{
		if (curSelectedNote != null) {
			if(curSelectedNote[2] != null) stepperSusLength.value = curSelectedNote[2];
			strumTimeInputText.text = '' + curSelectedNote[0];
		}
	}

    function updateGrid():Void
    {
		curRenderedNotes.clear();
		curRenderedEvents.clear();
		curRenderedSustains.clear();
		curRenderedNoteType.clear();

		nextRenderedNotes.clear();
		nextRenderedEvents.clear();
		nextRenderedSustains.clear();

        if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
            Conductor.bpm = _song.notes[curSection].bpm;
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.bpm = daBPM;
		}

        var beats:Float = getSectionBeats();
		for (i in _song.notes[curSection].sectionNotes)
		{
			var note:Note = setupNoteData(i, false);
			curRenderedNotes.add(note);
			if (note.sustainLength > 0)
				curRenderedSustains.add(setupSusNote(note, beats));
			var type:String = (note.noteType.startsWith('default')) ? note.noteType.replace('default', '').replace('-','') : note.noteType;
			if(i[3] != null && type != null && type.length > 0) {
				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, type, 24);
				daText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -32;
				daText.yAdd = 6;
				daText.borderSize = 1;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
		}

		// CURRENT EVENTS
        for(i in _song.notes[curSection].sectionEvents)
        {
            var note:Note = setupEventData(i, false);
            curRenderedEvents.add(note);
			var dataText:String = "";
			for(i in 0...note.eventData.length)
			{
				dataText += strigifyArray(note.eventData[i].values) + ' - ' + note.eventData[i].name;
				if (i < note.eventData.length - 1)
					dataText += "\n";
			}			
            var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, dataText, 12);
            daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
            daText.xAdd = -410;
            daText.borderSize = 1;
            curRenderedNoteType.add(daText);
            daText.sprTracker = note;
        }

		// NEXT SECTION
		var beats:Float = getSectionBeats(1);
		if(curSection < _song.notes.length-1) {
			for (i in _song.notes[curSection+1].sectionNotes)
			{
				var note:Note = setupNoteData(i, true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
				if (note.sustainLength > 0)
				{
					nextRenderedSustains.add(setupSusNote(note, beats));
				}
			}

            for (i in _song.notes[curSection+1].sectionEvents)
            {
				var note:Note = setupEventData(i, true);
				note.alpha = 0.6;
				nextRenderedEvents.add(note);
            }
		}
    }

	function setupEventData(i:Array<Dynamic>, isNextSection:Bool):Note
	{
		var daStrumTime = i[0];
		var note:Note = ForeverAssets.generateArrow(_song.assetModifier, daStrumTime, -1);
		var subEvent:SwagEvent = {
			strumTime: i[0],
			name: i[1],
			values: i[2]
		};				
		note.eventData.push(subEvent);
		note.texture = _song.arrowSkin;
		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.lane = Std.int(Math.max(Math.floor(i[1] / PlayState.numberOfKeys), 0));
		var beats:Float = getSectionBeats(isNextSection ? 1 : 0);
		note.y = getYfromStrumNotes(daStrumTime - sectionStartTime(), beats);
		if(note.y < -150) note.y = -150;
		return note;
	}

	function strigifyArray(array:Array<Dynamic>) {
        var value:String = "[";
		for(i in 0...array.length)
		{
            value += Std.string(array[i]);
            if (i < array.length - 1) value += ", ";
		}
        return value + "]";
    }

    function setupNoteData(i:Array<Dynamic>, isNextSection:Bool):Note
	{
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus:Dynamic = i[2];

		var note:Note = ForeverAssets.generateArrow(_song.assetModifier, daStrumTime, daNoteInfo % 4);
		note.sustainLength = i[2];
		note.noteType = NoteTypeRegistry.instance.resolveType(i[3]);
		note.texture = _song.arrowSkin;
		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(daNoteInfo * GRID_SIZE) + GRID_SIZE;
		if(isNextSection && _song.notes[curSection].mustHitSection != _song.notes[curSection+1].mustHitSection) {
			if(daNoteInfo > 3) {
				note.x -= GRID_SIZE * 4;
			} else if(daSus != null) {
				note.x += GRID_SIZE * 4;
			}
		}

		var beats:Float = getSectionBeats(isNextSection ? 1 : 0);
		note.y = getYfromStrumNotes(daStrumTime - sectionStartTime(), beats);
		if(note.y < -150) note.y = -150;
		return note;
	}

    function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length)
		{
			if(addedOne) retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}

	function setupSusNote(note:Note, beats:Float):FlxSprite {
		var height:Int = Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, GRID_SIZE * 16 * zoomList[curZoom]) + (GRID_SIZE * zoomList[curZoom]) - GRID_SIZE / 2);
		var minHeight:Int = Std.int((GRID_SIZE * zoomList[curZoom] / 2) + GRID_SIZE / 2);
		if(height < minHeight) height = minHeight;
		if(height < 1) height = 1; //Prevents error of invalid height

		var spr:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 4, note.y + GRID_SIZE / 2).makeGraphic(8, height);
		return spr;
	}

    function selectNote(note:Note):Void
    {
		for (i in _song.notes[curSection].sectionNotes)
		{
			if (i != curSelectedNote && i.length > 2 && i[0] == note.strumTime && i[1] % PlayState.numberOfKeys == note.noteData)
			{
				curSelectedNote = i;
				curSelectedEvent = null;
				break;
			}
		}
		updateGrid();
		updateNoteUI();
    }

	function selectEvent(note:Note) 
	{
		for (i in _song.notes[curSection].sectionEvents)
		{
			if (i != curSelectedEvent && i[0] == note.strumTime)
			{				
				curSelectedEvent = i;
				curSelectedNote = null;
				eventID = Std.int(curSelectedEvent[1].length) - 1;
				updateEventTxt();
				break;
			}
		}
		updateGrid();
	}

    function deleteNote(note:Note):Void
    {
		for (i in _song.notes[curSection].sectionNotes)
		{
			if (i[0] == note.strumTime && i[1] % PlayState.numberOfKeys == note.noteData)
			{
				if(i == curSelectedNote) curSelectedEvent = curSelectedNote = null;
				_song.notes[curSection].sectionNotes.remove(i);
				break;
			}
		}
		updateGrid();
    }

	function deleteEvent(note:Note):Void {
		for (i in _song.notes[curSection].sectionEvents)
		{
			if(i[0] == note.strumTime)
			{
				if(i == curSelectedEvent)
				{
					eventID = 0;
					curSelectedEvent = curSelectedNote = null;
					updateEventTxt();
				}
				_song.notes[curSection].sectionEvents.remove(i);
				break;
			}
		}
		updateGrid();
	}

	private function addNote():Void
	{
		var noteStrum = getStrumTime(dummyArrow.y * (getSectionBeats() / 4), false) + sectionStartTime();
		var noteData = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);
		if(noteData > -1)
		{
			curSelectedEvent = null;
			_song.notes[curSection].sectionNotes.push([noteStrum, noteData, 0, currentType]);
			curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];
			updateNoteUI();
		}
		else
		{
			eventID = 0;
			curSelectedEvent = [];
			curSelectedNote = null;
            setCurEvent(curEventDatas[eventID].name);
            for(data in curEventDatas) {
				var event:Array<Dynamic> = [noteStrum, data.name, convertEventValues(data.values)];
                _song.notes[curSection].sectionEvents.push(event);
				curSelectedEvent.push(event);
            }
		}

		if (FlxG.keys.pressed.CONTROL && noteData > -1){
			_song.notes[curSection].sectionNotes.push([noteStrum, (noteData + 4) % 8, 0]);
			updateNoteUI();
		} 

		if(curSelectedNote != null) strumTimeInputText.text = '' + curSelectedNote[0];
		

		updateGrid();
	}

	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height * leZoom, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height * leZoom);
	}
	
	function getYfromStrumNotes(strumTime:Float, beats:Float):Float
	{
		var value:Float = strumTime / (beats * 4 * Conductor.stepCrochet);
		return GRID_SIZE * beats * 4 * zoomList[curZoom] * value + gridBG.y;
	}

	function loadJson(song:String):Void
	{
        PlayState.SONG = Song.checkSong(Song.loadFromJson(PlayState.curDifficulty, song));
		FlxG.resetState();
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = getSongString();
		FlxG.save.flush();
	}

	public function getSongString(_:Null<String> = null) {
		return FunkyJson.stringify({
			"song": Song.optimizeJson(_song)
		}, _);
	}
	
	function saveJson(input:Dynamic, fileName:String) {
        final data:String = input is String ? input : FunkyJson.stringify(input, "\t");
        if (data.length > 0) {
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), '$fileName.json');
		}
    }

	private function saveEvents()
	{
		var metaEvents:Array<SwagSection> = [];
        for(section in _song.notes)
        {
            metaEvents.push(section.sectionEvents.length <= 0 ? {} : {
                sectionEvents: section.sectionEvents.copy()
            });
        }

        if (metaEvents.length > 1) {
			while (true) {
				var lastSec = metaEvents[metaEvents.length-1];
				if (lastSec == null) break;
				if (Reflect.fields(lastSec).length <= 0) 	metaEvents.pop();
				else 										break;
			}
		}

        var meta:SongMeta = {
            diffs: [PlayState.curDifficulty],
            events: metaEvents
        }
		
		saveJson(meta, "songMeta");
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

	function getSectionBeats(?section:Null<Int> = null)
	{
		if (section == null) section = curSection;
		var val:Null<Float> = null;
		
		if(_song.notes[section] != null) val = _song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}
}
