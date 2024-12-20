package gameObjects.character;

import meta.modding.events.ScriptEvent;
import data.CharacterData.CharacterRenderType;
import gameObjects.stage.Bopper;
import gameObjects.userInterface.notes.Strumline;
class BaseCharacter extends Bopper
{
    public var id(default, null):String;
    public var characterName(default, null):String;

    public var characterType(default, set):CharacterType = OTHER;
    public var customType(default, set):String = "NONE"; //For Extra Char?

    function set_characterType(value:CharacterType):CharacterType
        return this.characterType = value;

    function set_customType(value:String):String
        return this.customType = value.toUpperCase();

    public var holdTimer:Float = 0;
    public var isDead:Bool = false;
    public var isSing(get, never):Bool;
    public var debug:Bool = false;
    public var _data:CharacterData;
    public var characterOrigin(get, never):FlxPoint;
    function get_characterOrigin():FlxPoint
    {
        var xPos = (width / 2); // Horizontal center
        var yPos = (height); // Vertical bottom
        return new FlxPoint(xPos, yPos);
    }

    public var cornerPosition(get, set):FlxPoint;
    function get_cornerPosition():FlxPoint
    {
        return new FlxPoint(x, y);
    }

    function set_cornerPosition(value:FlxPoint):FlxPoint
    {
        var xDiff:Float = value.x - this.x;
        var yDiff:Float = value.y - this.y;
    
        this.cameraFocusPoint.x += xDiff;
        this.cameraFocusPoint.y += yDiff;
    
        super.set_x(value.x);
        super.set_y(value.y);
    
        return value;        
    }

    public var feetPosition(get, never):FlxPoint;

    function get_feetPosition():FlxPoint
    {
      return new FlxPoint(x + characterOrigin.x, y + characterOrigin.y);
    }
    
    public var cameraFocusPoint(default, null):FlxPoint = new FlxPoint(0, 0);

    override function set_x(value:Float):Float
    {
        if (value == this.x) return value;
      
        var xDiff = value - this.x;
        this.cameraFocusPoint.x += xDiff;
      
        return super.set_x(value);
    }

    override function set_y(value:Float):Float
    {
        if (value == this.y) return value;
      
        var yDiff = value - this.y;
        this.cameraFocusPoint.y += yDiff;
      
        return super.set_y(value);
    }

    public static function fetchData(charId:String):BaseCharacter {
        return CharacterRegistry.fetchCharacter(charId);
    }

    public function new(id:String, ?renderType:CharacterRenderType = Custom)
    {
        super();
        this.id = id;
    
        this._data = CharacterRegistry.fetchCharacterData(this.id);
        if (this._data == null)
            throw 'Could not find character data for id: $id';
        else if (this._data.renderType != renderType)
            throw 'Render type mismatch for character ($id): expected ${renderType}, got ${_data.renderType}';
        else
        {
            this.characterName = _data.name;
            this.name = _data.name;
            this.globalOffsets = _data.offsets;        
        }
        this.danceEvery = 2;
        this.shouldBop = false;
    }

    public function flipCharOffsets():Void 
    {
        this.flipXOffsets = true;
        switchAnim('danceLeft', 'danceRight');
        for (i in animOffsets.keys()) {
            if (i.startsWith("singRIGHT")) {
                var prefix = i.split("singRIGHT")[1];
                switchAnim('singRIGHT$prefix', 'singLEFT$prefix');
            }
        }
    }

    public static function setType(char:String):CharacterType 
    {
        switch(char.trim().toLowerCase())
        {
            case 'boyfriend'|'bf':
                return CharacterType.BF;
            case 'girlfriend'|'gf':
                return CharacterType.GF;
            case 'opponent'|'dad':
                return CharacterType.DAD;
        }
        return CharacterType.OTHER;
    }

    inline public function setFlipX(value:Bool):Void {
		this.flipXOffsets = false;
		if ((this.characterType == BF) != this._data.isPlayer)
			flipCharOffsets();
		this.flipX = value;
	}

    public function getDeathCameraOffsets():Array<Float>
        return _data.death?.cameraOffsets ?? [0.0, 0.0];

    public function getBaseScale():Float
        return _data.scale;

    public function getDeathCameraZoom():Float
        return _data.death?.cameraZoom ?? 1.0;

    public function getDeathPreTransitionDelay():Float
        return _data.death?.preTransitionDelay ?? 0.0;

    public function getDataFlipX():Bool
        return _data.flipX;

    public function resetCharacter(resetCamera:Bool = true):Void
    {
        this.dance(true);
        this.updateHitbox();
        if (resetCamera) this.resetCameraFocusPoint();
    }
    
    public function setScale(scale:Null<Float>):Void
    {
        if (scale == null) scale = 1.0;
        this.scale.x = scale;
        this.scale.y = scale;
        this.updateHitbox();

        this.x = feetPosition.x - characterOrigin.x + globalOffsets[0];
        this.y = feetPosition.y - characterOrigin.y + globalOffsets[1];
    }

    override function onCreate(event:ScriptEvent):Void
    {
        super.onCreate(event);
        this.dance(true);
        this.updateHitbox();
        this.resetCameraFocusPoint();
        super.onCreate(event);
    }

    function resetCameraFocusPoint():Void
    {
        var charCenterX = this.x + this.width / 2;
        var charCenterY = this.y + this.height / 2;
        this.cameraFocusPoint = new FlxPoint(charCenterX + _data.cameraOffsets[0], charCenterY + _data.cameraOffsets[1]);        
    }

    public override function onUpdate(event:UpdateScriptEvent):Void
    {
        super.onUpdate(event);
        
        if (isDead) return;

        if (justPressedNote() && this.characterType == BF) holdTimer = 0;

        if (isAnimationFinished() && !getCurrentAnimation().endsWith(Constants.ANIMATION_HOLD_SUFFIX) && hasAnimation(getCurrentAnimation() + Constants.ANIMATION_HOLD_SUFFIX))
            playAnim(getCurrentAnimation() + Constants.ANIMATION_HOLD_SUFFIX);

        if (isSing)
        {
            holdTimer += event.elapsed;
            var singTimeSec:Float = 8 * (Conductor.instance.stepLengthMs / Constants.MS_PER_SEC); // x beats, to ms.

            if (getCurrentAnimation().endsWith('miss')) singTimeSec *= 2;
            var shouldStopSinging:Bool = (this.characterType == BF) ? !isHoldingNote() : true;

            if (holdTimer > singTimeSec && shouldStopSinging)
            {
                holdTimer = 0;

                var currentAnimation:String = getCurrentAnimation();

                if (currentAnimation.endsWith(Constants.ANIMATION_HOLD_SUFFIX)) 
                    currentAnimation = currentAnimation.substring(0, currentAnimation.length - Constants.ANIMATION_HOLD_SUFFIX.length);


                var endAnimation:String = currentAnimation + Constants.ANIMATION_END_SUFFIX;
                if (hasAnimation(endAnimation))
                    playAnim(endAnimation);
                else
                    dance(true);    
            }
        }
    }

    public function getAnimationPrefixes():Array<String> {
		var prefixes:Array<String> = [];
		if (frames == null) return prefixes;
		for (i in frames.frames) {
			var anim = i.name.split('0')[0];
			if (!prefixes.contains(anim)) prefixes.push(anim);
		}
		return prefixes;
	}

    override function dance(force:Bool = false):Void
    {
        if (isDead) return;

        if (!force)
        {
          if (isSing) return;
    
          var currentAnimation:String = getCurrentAnimation();
          if ((currentAnimation == 'hey' || currentAnimation == 'cheer') && !isAnimationFinished()) return;
        }

        if (!force && isSing) return;
        super.dance();
    }

    public override function onNoteHit(event:HitNoteScriptEvent)
    {
        super.onNoteHit(event);

        if (event.eventCanceled || event.note.noAnim) return;
        onNoteSing(event.note);
    }
    
    public function onNoteSing(note:NoteSprite, ?suffix:String = "")
    {
        //so uh it will be cause duo sing it 
        if ((note.lane == 0  && characterType == BF && !note.gf 
            || note.lane == 1 && characterType == DAD && !note.gf 
            || note.gf && characterType == GF) && (customType == "NONE")) 
        {
            this.playSing(note.noteData.getDirection(), note.suffix + suffix, true);
        }
    }

    public function onSustainSing(note:SustainTrail, ?suffix:String = "")
    {
        if ((note.lane == 0  && characterType == BF && !note.gf 
            || note.lane == 1 && characterType == DAD && !note.gf 
            || note.gf && characterType == GF) && (customType == "NONE")) 
        {
            this.playSing(note.noteData.getDirection(), note.suffix + suffix, false);
        }
    }

    public override function onNoteMiss(event:NoteScriptEvent)
    {
        super.onNoteMiss(event);

        if (event.eventCanceled || event.note.noAnim) return;

        onNoteSing(event.note, 'miss');
    }

    public override function onSustainHit(event:SustainScriptEvent)
    {
        super.onSustainHit(event);

        if (event.eventCanceled || event.sustain.noAnim) return;

        onSustainSing(event.sustain);
    }
    
    public override function onNoteGhostMiss(event:GhostMissNoteScriptEvent)
    {
        super.onNoteGhostMiss(event);

        if (event.eventCanceled || !event.playAnim) return;

        if (characterType == BF)
        {
            this.playSing(event.dir, 'miss');
            this.holdTimer = 0;
        }
    }

    public var _singHoldTimer:Float = 0;
    public function playSing(direction:NoteDirection, ?suffix:String = '', hit:Bool = true):Void
    {
        var baseString = 'sing${direction.nameUpper}$suffix';
        
        this.holdTimer = 0;
		if (hit) {
			this.playAnim(baseString, true);
			this._singHoldTimer = 0;
		}
        else 
        {
            _singHoldTimer += FlxG.elapsed;
			if (_singHoldTimer >= ((2 / 24) - 0.01))
            {
				this.playAnim(baseString, true);
				this._singHoldTimer = 0;
			}
        }
    }

    function justPressedNote(player:Int = 1):Bool
    {
        return PlayerSettings.player1.controls.LEFT_P
        || PlayerSettings.player1.controls.DOWN_P
        || PlayerSettings.player1.controls.UP_P
        || PlayerSettings.player1.controls.RIGHT_P;
    }

    function isHoldingNote(player:Int = 1):Bool
    {
        return PlayerSettings.player1.controls.LEFT
        || PlayerSettings.player1.controls.DOWN
        || PlayerSettings.player1.controls.UP
        || PlayerSettings.player1.controls.RIGHT;
    }

    function get_isSing():Bool return getCurrentAnimation().startsWith('sing');

    public override function onDestroy(event:ScriptEvent):Void
        this.characterType = OTHER;
}

enum CharacterType
{
   BF;
   DAD;
   GF;
   OTHER;
}
 