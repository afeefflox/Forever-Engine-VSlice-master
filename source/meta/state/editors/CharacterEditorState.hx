package meta.state.editors;

import flixel.FlxObject;
import flixel.graphics.FlxGraphic;
import flixel.addons.display.FlxGridOverlay;

import flixel.animation.FlxAnimation;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.*;
import flixel.ui.FlxButton;
import flixel.util.FlxDestroyUtil;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import gameObjects.character.AnimateAtlasCharacter;

class CharacterEditorState extends MusicBeatState
{
    var character:BaseCharacter;
	var ghost:FlxSprite;
	var animateGhost:FlxAnimate;
	var cameraFollowPointer:FlxSprite;

	var silhouettes:FlxSpriteGroup;

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;
	var cameraZoomText:FlxText;
	var frameAdvanceText:FlxText;

	var healthBar:FlxSprite;
	var healthIcon:HealthIcon;

	var copiedOffset:Array<Float> = [0, 0];
	var _char:String = null;
	var _goToPlayState:Bool = true;

	var anims = null;
	var animsTxtGroup:FlxTypedGroup<FlxText>;
	var curAnim = 0;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;

	var UI_box:FlxUITabMenu;
	var UI_characterbox:FlxUITabMenu;

	var background:FlxSprite;

	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenu> = [];

	public function new(?char:String = null, ?goToPlayState:Bool = false)
	{
		this._char = char;
		this._goToPlayState = goToPlayState;
		if(this._char == null) this._char = Constants.DEFAULT_CHARACTER;

		super();
	}

	override function create()
	{
		super.create();

		camEditor = FlxG.camera;

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		background = FlxGridOverlay.create(10, 10);
		background.scrollFactor.set();
		add(background);

		animsTxtGroup = new FlxTypedGroup<FlxText>();
		silhouettes = new FlxSpriteGroup();
		add(silhouettes);

		var boyfriend:BaseCharacter = BaseCharacter.fetchData('dad'); 
		boyfriend.color = FlxColor.BLACK;
		boyfriend.active = false;
		silhouettes.add(boyfriend);
		silhouettes.alpha = 0.25;

		ghost = new FlxSprite();
		ghost.visible = false;
		ghost.alpha = ghostAlpha;
		add(ghost);

		addCharacter();

		cameraFollowPointer = new FlxSprite().loadGraphic(FlxGraphic.fromClass(GraphicCursorCross));
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		add(cameraFollowPointer);

		healthBar = new FlxSprite(30, FlxG.height - 75).loadGraphic(Paths.image('UI/default/base/healthBar'));
		healthBar.scrollFactor.set();
		add(healthBar);
		healthBar.cameras = [camHUD];

		healthIcon = new HealthIcon(character._data.healthIcon.id);
		healthIcon.y = FlxG.height - 150;
		add(healthIcon);
		healthIcon.cameras = [camHUD];

		animsTxtGroup.cameras = [camHUD];
		add(animsTxtGroup);

		cameraZoomText = new FlxText(0, 50, 200, 'Zoom: 1x');
		cameraZoomText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		cameraZoomText.scrollFactor.set();
		cameraZoomText.borderSize = 1;
		cameraZoomText.screenCenter(X);
		cameraZoomText.cameras = [camHUD];
		add(cameraZoomText);

		frameAdvanceText = new FlxText(0, 75, 350, '');
		frameAdvanceText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		frameAdvanceText.scrollFactor.set();
		frameAdvanceText.borderSize = 1;
		frameAdvanceText.screenCenter(X);
		frameAdvanceText.cameras = [camHUD];
		add(frameAdvanceText);

		FlxG.mouse.visible = true;
		FlxG.camera.zoom = 1;

		makeUIMenu();

		updatePointerPos();
	}

	function addCharacter()
	{
		var pos:Int = -1;
		if(character != null)
		{
			pos = members.indexOf(character);
			remove(character);
			character.destroy();
		}

		character = BaseCharacter.fetchData(_char);

		if(pos > -1) insert(pos, character);
		else add(character);
		updateCharacterPositions();
		reloadAnimList();
	}

	function makeUIMenu()
	{
		var tabs = [
			{name: 'Ghost', label: 'Ghost'},
			{name: 'Settings', label: 'Settings'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camHUD];

		UI_box.resize(250, 120);
		UI_box.x = FlxG.width - 275;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		var tabs = [
			{name: 'Character', label: 'Character'},
			{name: 'Animations', label: 'Animations'},
		];
		UI_characterbox = new FlxUITabMenu(null, tabs, true);
		UI_characterbox.cameras = [camHUD];

		UI_characterbox.resize(350, 280);
		UI_characterbox.x = UI_box.x - 100;
		UI_characterbox.y = UI_box.y + UI_box.height;
		UI_characterbox.scrollFactor.set();
		add(UI_characterbox);
		add(UI_box);

		addGhostUI();
		addCharacterUI();
		addSettingsUI();
		addAnimationsUI();
		

		UI_box.selected_tab_id = 'Settings';
		UI_characterbox.selected_tab_id = 'Character';
	}

	var ghostAlpha:Float = 0.6;
	function addGhostUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Ghost";

		var makeGhostButton:FlxButton = new FlxButton(25, 15, "Make Ghost", function() 
		{
			var anim = anims[curAnim];
			if(!character.isAnimationNull())
			{
				if(Std.isOfType(character, AnimateAtlasCharacter))
				{
					var atlasChar:AnimateAtlasCharacter = cast(character, AnimateAtlasCharacter);
					if(animateGhost == null) //If I created the animateGhost on create() and you didn't load an atlas, it would crash the game on destroy, so we create it here
					{
						animateGhost = new FlxAnimate(ghost.x, ghost.y, Paths.animateAtlas(atlasChar._data.assetPath));
						animateGhost.showPivot = false;
						insert(members.indexOf(ghost), animateGhost);
						animateGhost.active = false;
					}

					if(anim.frameIndices != null && anim.frameIndices.length > 0)
						animateGhost.anim.addBySymbolIndices('anim', anim.prefix, anim.frameIndices, 0, false);
					else
						animateGhost.anim.addBySymbol('anim', anim.prefix, 0, false);

					animateGhost.anim.play('anim', true, false, atlasChar.mainSprite.anim.curFrame);
					animateGhost.anim.pause();
				}
				else
				{
					ghost.loadGraphic(character.graphic);
					ghost.frames.frames = character.frames.frames;
					ghost.animation.copyFrom(character.animation);
					ghost.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
					ghost.animation.pause();
				}

				var spr:FlxSprite = Std.isOfType(character, AnimateAtlasCharacter) ? animateGhost : ghost;
				if(spr != null)
				{
					spr.setPosition(character.x, character.y);
					spr.antialiasing = character.antialiasing;
					spr.flipX = character.flipX;
					spr.alpha = ghostAlpha;

					spr.scale.set(character.scale.x, character.scale.y);
					spr.updateHitbox();

					spr.offset.set(character.offset.x, character.offset.y);
					spr.visible = true;

					var otherSpr:FlxSprite = (spr == animateGhost) ? ghost : animateGhost;
					if(otherSpr != null) otherSpr.visible = false;
				}
			}
		});

		var highlightGhost:FlxUICheckBox = new FlxUICheckBox(20 + makeGhostButton.x + makeGhostButton.width, makeGhostButton.y, null, null, "Highlight Ghost", 100);
		highlightGhost.callback = function()
		{
			var value = highlightGhost.checked ? 125 : 0;
			ghost.colorTransform.redOffset = ghost.colorTransform.greenOffset = ghost.colorTransform.blueOffset = value;
			if(animateGhost != null)
				animateGhost.colorTransform.redOffset = animateGhost.colorTransform.greenOffset = animateGhost.colorTransform.blueOffset = value;
		};

		var ghostAlphaSlider:FlxUISlider = new FlxUISlider(this, 'ghostAlpha', 10, makeGhostButton.y + 25, 0, 1, 210, null, 5, FlxColor.WHITE, FlxColor.BLACK);
		ghostAlphaSlider.nameLabel.text = 'Opacity:';
		ghostAlphaSlider.decimals = 2;
		ghostAlphaSlider.callback = function(relativePos:Float) {
			ghost.alpha = ghostAlpha;
			if(animateGhost != null) animateGhost.alpha = ghostAlpha;
		};
		ghostAlphaSlider.value = ghostAlpha;

		tab_group.add(makeGhostButton);
		tab_group.add(highlightGhost);
		tab_group.add(ghostAlphaSlider);
		UI_box.addGroup(tab_group);
	}

	var check_player:FlxUICheckBox;
	var charDropDown:FlxUIDropDownMenu;
	function addSettingsUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";

		check_player = new FlxUICheckBox(10, 60, null, null, "Playable Character", 100);
		check_player.checked = character._data.isPlayer;
		check_player.callback = function()
		{
			character._data.isPlayer = !character._data.isPlayer;
			character.setFlipX(flipXCheckBox.checked);
		};

		var reloadCharacter:FlxButton = new FlxButton(140, 20, "Reload Char", function()
		{
			addCharacter();
			updatePointerPos();
			reloadCharacterOptions();
			reloadCharacterDropDown();
		});

		var templateCharacter:FlxButton = new FlxButton(140, 50, "Load Template", function()
		{
			character._data = CharacterRegistry.DEFAULT_CHARACTER;
			character.color = FlxColor.WHITE;
			character.alpha = 1;
			reloadAnimList();
			reloadCharacterOptions();
			updateCharacterPositions();
			updatePointerPos();
			reloadCharacterDropDown();
		});
		templateCharacter.color = FlxColor.RED;
		templateCharacter.label.color = FlxColor.WHITE;

		charDropDown = new FlxUIDropDownMenu(10, 30, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(index:String)
		{
			var intended = characterList[Std.parseInt(index)];
			if(intended == null || intended.length < 1) return;
			if (Paths.exists(Paths.json('characters/$intended'), TEXT))
			{
				_char = intended;
				check_player.checked = character._data.isPlayer;
				addCharacter();
				reloadCharacterOptions();
				reloadCharacterDropDown();
				updatePointerPos();
			}
			else
			{
				reloadCharacterDropDown();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		});
		reloadCharacterDropDown();
		charDropDown.selectedLabel = _char;
		blockPressWhileScrolling.push(charDropDown);

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 0, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		tab_group.add(charDropDown);
		UI_box.addGroup(tab_group);
	}

	var animationDropDown:FlxUIDropDownMenu;
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;
	function addAnimationsUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Animations";

		animationInputText = new FlxUIInputText(15, 85, 80, '', 8);
		blockPressWhileTypingOn.push(animationInputText);
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		blockPressWhileTypingOn.push(animationNameInputText);
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		blockPressWhileTypingOn.push(animationIndicesInputText);
		animationFramerate = new FlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		blockPressWhileTypingOnStepper.push(animationFramerate);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, null, null, "Should it Loop?", 100);
		

		animationDropDown = new FlxUIDropDownMenu(15, animationInputText.y - 55, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			var anim:AnimationData = character._data.animations[selectedAnimation];
			animationInputText.text = anim.name;
			animationNameInputText.text = anim.prefix;
			animationLoopCheckBox.checked = anim.looped;
			animationFramerate.value = anim.frameRate;

			var indicesStr:String = anim.frameIndices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});
		blockPressWhileScrolling.push(animationDropDown);

		var addUpdateButton:FlxButton = new FlxButton(70, animationIndicesInputText.y + 60, "Add/Update", function() {
			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
			if(indicesStr.length > 1) {
				for (i in 0...indicesStr.length) {
					var index:Int = Std.parseInt(indicesStr[i]);
					if(indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1) {
						indices.push(index);
					}
				}
			}

			var lastAnim:String = (character._data.animations[curAnim] != null) ? character._data.animations[curAnim].name : '';
			var lastOffsets:Array<Float> = [0, 0];
			for (anim in character._data.animations)
				if(animationInputText.text == anim.name) {
					lastOffsets = anim.offsets;
					if(character.animOffsets.exists(animationInputText.text))
					{
						if(Std.isOfType(character, AnimateAtlasCharacter))
						{
							var atlasChar:AnimateAtlasCharacter = cast(character, AnimateAtlasCharacter);
							atlasChar.mainSprite.anim.animsMap.remove(animationInputText.text);
						}
						else
							character.animation.remove(animationInputText.text);
					}
					character._data.animations.remove(anim);
				}

			var addedAnim:AnimationData = newAnim(animationInputText.text, animationNameInputText.text);
			addedAnim.frameRate = Math.round(animationFramerate.value);
			addedAnim.looped = animationLoopCheckBox.checked;
			addedAnim.frameIndices = indices;
			addedAnim.offsets = lastOffsets;
			if(Std.isOfType(character, AnimateAtlasCharacter))
			{
				var atlasChar:AnimateAtlasCharacter = cast(character, AnimateAtlasCharacter);
				FlxAnimationUtil.addAnimateAtlasAnimation(atlasChar.mainSprite, addedAnim);
			}
			else
				FlxAnimationUtil.addAtlasAnimation(character, addedAnim);
			
			character._data.animations.push(addedAnim);

			reloadAnimList();
			@:arrayAccess curAnim = Std.int(Math.max(0, character._data.animations.indexOf(addedAnim)));
			character.playAnim(addedAnim.name, true);
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:FlxButton = new FlxButton(180, animationIndicesInputText.y + 60, "Remove", function() {
			for (anim in character._data.animations)
				if(animationInputText.text == anim.name)
				{
					var resetAnim:Bool = false;
					if(anim.name == character.getCurrentAnimation()) resetAnim = true;
					if(character.animOffsets.exists(anim.name))
					{
						if(Std.isOfType(character, AnimateAtlasCharacter))
						{
							var atlasChar:AnimateAtlasCharacter = cast(character, AnimateAtlasCharacter);
							atlasChar.mainSprite.anim.animsMap.remove(anim.name);
						}
						else
							character.animation.remove(anim.name);
						character.animOffsets.remove(anim.name);
						character._data.animations.remove(anim);
					}

					if(resetAnim && character._data.animations.length > 0) {
						curAnim = FlxMath.wrap(curAnim, 0, anims.length-1);
						character.playAnim(anims[curAnim].name, true);
						updateTextColors();
					}
					reloadAnimList();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
		});
		reloadAnimList();
		animationDropDown.selectedLabel = anims[0] != null ? anims[0].name : '';

		var autoButton:FlxUIButton = new FlxUIButton(animationDropDown.x + 150, animationDropDown.y, 'Auto Anims', function () {
			for (anim in character._data.animations)
			{
				if(character.animOffsets.exists(anim.name))
				{
					character.animation.remove(anim.name);
					character.animOffsets.remove(anim.name);
					character._data.animations.remove(anim);					
				}
			}

			for (i in character.getAnimationPrefixes()) 
			{
				var prefix = i;
				if((prefix.startsWith('sing') || prefix.startsWith('idle')) && (!prefix.endsWith('-alt') || !prefix.endsWith('miss'))) 
					prefix += '0';
				var addedAnim:AnimationData = newAnim(i, prefix);	
				FlxAnimationUtil.addAtlasAnimation(character, addedAnim);
				character._data.animations.push(addedAnim);
				@:arrayAccess curAnim = Std.int(Math.max(0, character._data.animations.indexOf(addedAnim)));
			}

			reloadAnimList();
			character.dance();
		});
		autoButton.visible = (!Std.isOfType(character, AnimateAtlasCharacter)); //cuz atlas mostly use indices I believe

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation Symbol Name/Tag:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(autoButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);
		UI_characterbox.addGroup(tab_group);
	}

	var imageInputText:FlxUIInputText;
	var healthIconInputText:FlxUIInputText;
	var nameInputText:FlxUIInputText;

	var scaleStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;

	var flipXCheckBox:FlxUICheckBox;
	var antialiasingCheckBox:FlxUICheckBox;
	function addCharacterUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Character";

		imageInputText = new FlxUIInputText(15, 30, 200, character._data.assetPath, 8);
		blockPressWhileTypingOn.push(imageInputText);
		var reloadImage:FlxButton = new FlxButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			var lastAnim = character.getCurrentAnimation();
			character._data.assetPath = imageInputText.text;
			reloadCharacterImage();
			if(!character.isAnimationNull()) {
				character.playAnim(lastAnim, true);
			}
		});

		healthIconInputText = new FlxUIInputText(15, imageInputText.y + 35, 75, character._data.healthIcon.id, 8);
		blockPressWhileTypingOn.push(healthIconInputText);
		nameInputText = new FlxUIInputText(15, healthIconInputText.y + 35, 75, character._data.name, 8);
		blockPressWhileTypingOn.push(nameInputText);

		scaleStepper = new FlxUINumericStepper(15, nameInputText.y + 45, 0.1, 1, 0.05, 10, 1);
		blockPressWhileTypingOnStepper.push(scaleStepper);

		flipXCheckBox = new FlxUICheckBox(scaleStepper.x + 80, scaleStepper.y, null, null, "Flip X", 50);
		flipXCheckBox.callback = function() {
			character._data.flipX = flipXCheckBox.checked;
			character.setFlipX(flipXCheckBox.checked);
		};

		antialiasingCheckBox = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, null, null, "Antialiasing", 80);
		antialiasingCheckBox.checked = character.antialiasing;
		antialiasingCheckBox.callback = function() {
			character._data.antialiasing = !character._data.antialiasing;
			character.antialiasing = character._data.antialiasing;
		};

		positionXStepper = new FlxUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, character._data.offsets[0], -9000, 9000, 0);
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, character._data.offsets[1], -9000, 9000, 0);
		blockPressWhileTypingOnStepper.push(positionXStepper);
		blockPressWhileTypingOnStepper.push(positionYStepper);

		positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, character._data.cameraOffsets[0], -9000, 9000, 0);
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, character._data.cameraOffsets[1], -9000, 9000, 0);
		blockPressWhileTypingOnStepper.push(positionCameraXStepper);
		blockPressWhileTypingOnStepper.push(positionCameraYStepper);

		var saveCharacterButton:FlxButton = new FlxButton(reloadImage.x, antialiasingCheckBox.y + 40, "Save Character", function() {
			saveCharacter();
		});

		tab_group.add(new FlxText(15, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 0, 'Health icon name:'));
		tab_group.add(new FlxText(15, nameInputText.y - 18, 0, 'Character Name:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Camera X/Y:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(healthIconInputText);
		tab_group.add(nameInputText);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(antialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(saveCharacterButton);
		UI_characterbox.addGroup(tab_group);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id != FlxUIInputText.CHANGE_EVENT && id != FlxUINumericStepper.CHANGE_EVENT) return;

		if(sender is FlxUIInputText)
		{
			if(sender == healthIconInputText) {
				healthIcon.char = healthIconInputText.text;
				character._data.healthIcon.id = healthIconInputText.text;
			}
			else if(sender == nameInputText)
				character._data.name = nameInputText.text;
			else if(sender == imageInputText)
				character._data.assetPath = imageInputText.text;
		}
		else if(sender is FlxUINumericStepper)
		{
			if (sender == scaleStepper)
			{
				reloadCharacterImage();
				character._data.scale = sender.value;
				character.setScale(character._data.scale);
				updatePointerPos(false);
			}
			else if(sender == positionXStepper)
			{
				character._data.offsets[0] = positionXStepper.value;
				updateCharacterPositions();
			}
			else if(sender == positionYStepper)
			{
				character._data.offsets[1] = positionYStepper.value;
				updateCharacterPositions();
			}
			else if(sender == positionCameraXStepper)
			{
				character._data.cameraOffsets[0] = positionCameraXStepper.value;
				updatePointerPos();
			}
			else if(sender == positionCameraYStepper)
			{
				character._data.cameraOffsets[1] = positionCameraYStepper.value;
				updatePointerPos();
			}
		}
	}

	function reloadCharacterImage()
	{
		var lastAnim:String = character.getCurrentAnimation();
		var anims:Array<AnimationData> = character._data.animations.copy();
		character.color = FlxColor.WHITE;
		character.alpha = 1;

		if (Paths.exists(Paths.json('characters/${character._data.assetPath}/Animation'), TEXT))
		{
			try
			{
				character = new AnimateAtlasCharacter(_char);
			}
			catch(e:Dynamic)
			{
				FlxG.log.warn('Could not load atlas ${character._data.assetPath}: $e');
			}
		}
		else
			character.frames = Paths.getAtlas(character._data.assetPath);

		if(Std.isOfType(character, AnimateAtlasCharacter))
		{
			var atlasChar:AnimateAtlasCharacter = cast(character, AnimateAtlasCharacter);
			FlxAnimationUtil.addAnimateAtlasAnimations(atlasChar.mainSprite, atlasChar._data.animations);
    
			for (anim in atlasChar._data.animations)
			{
			  if (anim.offsets == null)
				atlasChar.setAnimationOffsets(anim.name, 0, 0);
			  else
				atlasChar.setAnimationOffsets(anim.name, anim.offsets[0], anim.offsets[1]);
			}
		}
		else
		{
			FlxAnimationUtil.addAtlasAnimations(character, character._data.animations);

			for (anim in character._data.animations)
			{
			  if (anim.offsets == null)
				character.setAnimationOffsets(anim.name, 0, 0);
			  else
				character.setAnimationOffsets(anim.name, anim.offsets[0], anim.offsets[1]);
			}
		}
				

		if(anims.length > 0)
		{
			if(lastAnim != '') character.playAnim(lastAnim, true);
			else character.dance();
		}
	}

	function reloadCharacterOptions() {
		if(UI_characterbox == null) return;

		check_player.checked = character._data.isPlayer;
		imageInputText.text = character._data.assetPath;
		healthIconInputText.text = character._data.healthIcon.id;
		nameInputText.text = character._data.name;
		scaleStepper.value = character._data.scale;
		flipXCheckBox.checked = character._data.flipX;
		antialiasingCheckBox.checked = character._data.antialiasing;
		positionXStepper.value = character._data.offsets[0];
		positionYStepper.value = character._data.offsets[1];
		positionCameraXStepper.value = character._data.cameraOffsets[0];
		positionCameraYStepper.value = character._data.cameraOffsets[1];
		reloadAnimationDropDown();
	}

	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;
	var undoOffsets:Array<Float> = null;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				Init.toggleVolumeKeys(false);
				return;
			}
		}

		for (stepper in blockPressWhileTypingOnStepper)
		{
			@:privateAccess
			var leText:Dynamic = stepper.text_field;
			var leText:FlxUIInputText = leText;
			if (leText.hasFocus)
			{
				Init.toggleVolumeKeys(false);
				return;
			}
		}
		for (dropDownMenu in blockPressWhileScrolling)
		{
			if (dropDownMenu.dropPanel.visible)
			{
				Init.toggleVolumeKeys(false);
				return;
			}
		}

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if(FlxG.keys.pressed.SHIFT)
		{
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

		// CAMERA CONTROLS
		if (FlxG.keys.pressed.J) FlxG.camera.scroll.x -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K) FlxG.camera.scroll.y += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L) FlxG.camera.scroll.x += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I) FlxG.camera.scroll.y -= elapsed * 500 * shiftMult * ctrlMult;

		var lastZoom = FlxG.camera.zoom;
		if(FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL) FlxG.camera.zoom = 1;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
		}
		else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
		}

		if(lastZoom != FlxG.camera.zoom) cameraZoomText.text = 'Zoom: ' + FlxMath.roundDecimal(FlxG.camera.zoom, 2) + 'x';

		// CHARACTER CONTROLS
		var changedAnim:Bool = false;
		if(anims.length > 1)
		{
			if(FlxG.keys.justPressed.W && (changedAnim = true)) curAnim--;
			else if(FlxG.keys.justPressed.S && (changedAnim = true)) curAnim++;

			if(changedAnim)
			{
				undoOffsets = null;
				curAnim = FlxMath.wrap(curAnim, 0, anims.length-1);
				character.playAnim(anims[curAnim].name, true);
				updateTextColors();
			}
		}

		var changedOffset = false;
		var moveKeysP = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
		var moveKeys = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
		if(moveKeysP.contains(true))
		{
			character.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
			character.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
			changedOffset = true;
		}

		if(moveKeys.contains(true))
		{
			holdingArrowsTime += elapsed;
			if(holdingArrowsTime > 0.6)
			{
				holdingArrowsElapsed += elapsed;
				while(holdingArrowsElapsed > (1/60))
				{
					character.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
					character.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
					holdingArrowsElapsed -= (1/60);
					changedOffset = true;
				}
			}
		}
		else holdingArrowsTime = 0;

		if(FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
		{
			character.offset.x -= FlxG.mouse.deltaScreenX;
			character.offset.y -= FlxG.mouse.deltaScreenY;
			changedOffset = true;
		}

		if(FlxG.keys.pressed.CONTROL)
		{
			if(FlxG.keys.justPressed.C)
			{
				copiedOffset[0] = character.offset.x;
				copiedOffset[1] = character.offset.y;
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.V)
			{
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.x = copiedOffset[0];
				character.offset.y = copiedOffset[1];
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.R)
			{
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.set(0, 0);
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.Z && undoOffsets != null)
			{
				character.offset.x = undoOffsets[0];
				character.offset.y = undoOffsets[1];
				changedOffset = true;
			}
		}

		var anim = anims[curAnim];
		if(changedOffset && anim != null && anim.offsets != null)
		{
			anim.offsets[0] = Std.int(character.offset.x);
			anim.offsets[1] = Std.int(character.offset.y);

			var myText:FlxText = animsTxtGroup.members[curAnim];
			myText.text = anim.name + ": " + anim.offsets;
			character.setAnimationOffsets(anim.name, character.offset.x, character.offset.y);
		}

		var txt = 'ERROR: No Animation Found';
		var clr = FlxColor.RED;
		if(!character.isAnimationNull())
		{
			if(FlxG.keys.pressed.A || FlxG.keys.pressed.D)
			{
				holdingFrameTime += elapsed;
				if(holdingFrameTime > 0.5) holdingFrameElapsed += elapsed;
			}
			else holdingFrameTime = 0;

			if(FlxG.keys.justPressed.SPACE)
				character.playAnim(character.getCurrentAnimation(), true);

			var frames:Int = 0;
			var length:Int = 0;

			if(Std.isOfType(character, AnimateAtlasCharacter))
			{
				var atlasChar:AnimateAtlasCharacter = cast(character, AnimateAtlasCharacter);
				frames = atlasChar.mainSprite.anim.curFrame;
				length = atlasChar.mainSprite.anim.length;
			}
			else
			{
				frames = character.animation.curAnim.curFrame;
				length = character.animation.curAnim.numFrames;

			}

			if(FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || holdingFrameTime > 0.5)
			{
				var isLeft = false;
				if((holdingFrameTime > 0.5 && FlxG.keys.pressed.A) || FlxG.keys.justPressed.A) isLeft = true;
				character.animPaused = true;

				if(holdingFrameTime <= 0.5 || holdingFrameElapsed > 0.1)
				{
					frames = FlxMath.wrap(frames + Std.int(isLeft ? -shiftMult : shiftMult), 0, length-1);
					if(Std.isOfType(character, AnimateAtlasCharacter))
					{
						var atlasChar:AnimateAtlasCharacter = cast(character, AnimateAtlasCharacter);
						atlasChar.mainSprite.anim.curFrame = frames;
					}
					else
						character.animation.curAnim.curFrame = frames;
					holdingFrameElapsed -= 0.1;
				}
			}

			txt = 'Frames: ( $frames / ${length-1} )';
			//if(character.animation.curAnim.paused) txt += ' - PAUSED';
			clr = FlxColor.WHITE;
		}
		if(txt != frameAdvanceText.text) frameAdvanceText.text = txt;
		frameAdvanceText.color = clr;

		// OTHER CONTROLS
		if(FlxG.keys.justPressed.F12)
			silhouettes.visible = !silhouettes.visible;
		if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.ENTER)
		{
			FlxG.mouse.visible = false;
			if(!_goToPlayState)
			{
				FlxG.switchState(new meta.state.menus.MainMenuState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
			else Main.switchState(new PlayState());
			return;
		}

		background.setGraphicSize(Std.int(background.width / FlxG.camera.zoom));
	}

	inline function updatePointerPos(?snap:Bool = true)
	{
		character.cameraFocusPoint.x += character._data.cameraOffsets[0];
		character.cameraFocusPoint.y += character._data.cameraOffsets[1];
		cameraFollowPointer.setPosition(character.cameraFocusPoint.x, character.cameraFocusPoint.y);
		if(snap)
		{
			FlxG.camera.scroll.set(cameraFollowPointer.x, cameraFollowPointer.y);
		}
	}

	inline function reloadAnimList()
	{
		anims = character._data.animations;

		if(anims.length > 0) character.playAnim(anims[0].name, true);
		curAnim = 0;

		for (text in animsTxtGroup)
			text.kill();

		var daLoop = 0;
		for (anim in anims)
		{
			var text:FlxText = animsTxtGroup.recycle(FlxText);
			text.x = 10;
			text.y = 32 + (20 * daLoop);
			text.fieldWidth = 400;
			text.fieldHeight = 20;
			text.text = anim.name + ": " + anim.offsets;
			text.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			animsTxtGroup.add(text);

			daLoop++;
		}
		updateTextColors();
		if(animationDropDown != null) reloadAnimationDropDown();
	}

	inline function updateTextColors()
	{
		var daLoop = 0;
		for (text in animsTxtGroup)
		{
			text.color = FlxColor.WHITE;
			if(daLoop == curAnim) text.color = FlxColor.LIME;
			daLoop++;
		}
	}

	inline function updateCharacterPositions()
	{
		character.x += character._data.offsets[0];
		character.y += character._data.offsets[1];
	}

	inline function newAnim(anim:String, prefix:String):AnimationData
	{
		return {
			name: anim,
			prefix: prefix,
			assetPath: "",
			offsets: [0, 0],
			looped: false,
			frameRate: 24,
			frameIndices: []
		};
	}

	var characterList:Array<String> = [];
	function reloadCharacterDropDown() {
		characterList = CharacterRegistry.listCharacterIds();
		charDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(characterList, true));
		charDropDown.selectedLabel = _char;
	}

	function reloadAnimationDropDown() {
		var animList:Array<String> = [];
		for (anim in anims) animList.push(anim.name);
		if(animList.length < 1) animList.push('NO ANIMATIONS'); //Prevents crash

		animationDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(animList, true));
	}

	// save
	var _file:FileReference;
	function onSaveComplete(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		if(_file == null) return;
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
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveCharacter() {
		if(_file != null) return;

		var charData:CharacterData = Reflect.copy(character._data);
		var data:String = FunkyJson.stringify(charData, "\t");

		if ((data != null) && (data.length > 0)) 
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), '$_char.json');
		}
	}
}