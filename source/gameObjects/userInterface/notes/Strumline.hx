package gameObjects.userInterface.notes;
import flixel.util.FlxSignal.FlxTypedSignal;
class Strumline extends FlxSpriteGroup
{
    public static final DIRECTIONS:Array<NoteDirection> = [NoteDirection.LEFT, NoteDirection.DOWN, NoteDirection.UP, NoteDirection.RIGHT];
    public static final STRUMLINE_SIZE:Int = 104;
    public static final NOTE_SPACING:Int = STRUMLINE_SIZE + 8;

    public static final INITIAL_OFFSET = -0.275 * STRUMLINE_SIZE;
    static final NUDGE:Float = 2.0;
  
    static final KEY_COUNT:Int = 4;
    static final NOTE_SPLASH_CAP:Int = 6;
  
    static var RENDER_DISTANCE_MS(get, never):Float;
    var heldKeys:Array<Bool> = [];
    static function get_RENDER_DISTANCE_MS():Float
        return FlxG.height / Constants.PIXELS_PER_MS;

    public var scrollSpeed:Float = 1.0;

    public function resetScrollSpeed():Void 
    {
        scrollSpeed = PlayState.instance?.currentChart?.scrollSpeed ?? 1.0;
    }

    public var notes:FlxTypedSpriteGroup<NoteSprite> = new FlxTypedSpriteGroup<NoteSprite>();
    public var holdNotes:FlxTypedSpriteGroup<SustainTrail> = new FlxTypedSpriteGroup<SustainTrail>();
  
    public var onNoteIncoming:FlxTypedSignal<NoteSprite->Void>;
  
    var strumlineNotes:FlxTypedSpriteGroup<StrumlineNote>;
    var noteSplashes:FlxTypedSpriteGroup<NoteSplash>;
    var noteHoldCovers:FlxTypedSpriteGroup<NoteHoldCover>;
  
    var notesVwoosh:FlxTypedSpriteGroup<NoteSprite>;
    var holdNotesVwoosh:FlxTypedSpriteGroup<SustainTrail>;
  
    final noteStyle:NoteStyle;

    var noteData:Array<SongNoteData> = [];
    var nextNoteIndex:Int = -1;

    public var downscroll:Bool = false;
    public var botplay:Bool = false;
    public var lane:Int = 0;
    var ghostTapTimer:Float = 0.0;
    public function new(noteStyle:NoteStyle, ?downscroll:Bool = false, ?botplay:Bool = false, lane:Int = 0)
    {
        super();
        
        this.noteStyle = noteStyle;
        this.downscroll = downscroll;
        this.botplay = botplay;
        this.lane = lane;

        this.holdNotes = new FlxTypedSpriteGroup<SustainTrail>();
        this.add(this.holdNotes);

        this.holdNotesVwoosh = new FlxTypedSpriteGroup<SustainTrail>();
        this.add(this.holdNotesVwoosh);

        this.strumlineNotes = new FlxTypedSpriteGroup<StrumlineNote>();
        this.strumlineNotes.zIndex = 20;
        this.add(this.strumlineNotes);

        this.notes = new FlxTypedSpriteGroup<NoteSprite>();
        this.add(this.notes);

        this.notesVwoosh = new FlxTypedSpriteGroup<NoteSprite>();
        this.add(this.notesVwoosh);

        this.noteHoldCovers = new FlxTypedSpriteGroup<NoteHoldCover>(0, 0, 4);
        this.noteHoldCovers.zIndex = 40;
        this.add(this.noteHoldCovers);

        this.noteSplashes = new FlxTypedSpriteGroup<NoteSplash>(0, 0, NOTE_SPLASH_CAP);
        this.noteSplashes.zIndex = 50;
        this.add(this.noteSplashes);

        switch(Init.trueSettings.get("Clip Style").toLowerCase())
        {
            case 'stepmania':
                this.holdNotes.zIndex = 10;
                this.holdNotesVwoosh.zIndex = 11;
                this.notes.zIndex = 30;
                this.notesVwoosh.zIndex = 31;
            case 'fnf':
                this.holdNotes.zIndex = 30;
                this.holdNotesVwoosh.zIndex = 31;
                this.notes.zIndex = 40;
                this.notesVwoosh.zIndex = 41;
        }
    
        this.refresh();
    
        this.onNoteIncoming = new FlxTypedSignal<NoteSprite->Void>();
        resetScrollSpeed();


        for (i in 0...KEY_COUNT)
        {
            var child:StrumlineNote = new StrumlineNote(noteStyle, DIRECTIONS[i]);
            child.x = getXPos(DIRECTIONS[i]);
            child.x += INITIAL_OFFSET;
            child.y = 0;
            noteStyle.applyStrumlineOffsets(child);
            this.strumlineNotes.add(child);
            heldKeys.push(false);
        }
        this.active = true;

        this.y = 25 + (downscroll ? FlxG.height - 150 : 0) - 10;
    }

    public function refresh():Void
    {
        sort(SortUtil.byZIndex, FlxSort.ASCENDING);
    }

    override function get_width():Float
    {
        return KEY_COUNT * Strumline.NOTE_SPACING;
    }

    public override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        updateNotes();
        updateGhostTapTimer(elapsed);
    }

    public function mayGhostTap():Bool
    {
        if (!Init.trueSettings.get('Ghost Tapping') || getNotesMayHit().length > 0 || getHoldNotesHitOrMissed().length > 0 || ghostTapTimer > 0.0)  return false;
        return true;
    }

    public static function getArrowFromNumber(numb:Int)
    {
        var stringSect:String = '';
		switch (numb)
		{
			case(0):
				stringSect = 'left';
			case(1):
				stringSect = 'down';
			case(2):
				stringSect = 'up';
			case(3):
				stringSect = 'right';
		}
		return stringSect;
    }

    function updateGhostTapTimer(elapsed:Float):Void
    {
        if (getNotesOnScreen().length > 0 || !Init.trueSettings.get('Ghost Tapping')) return;

        ghostTapTimer -= elapsed;
    
        if (ghostTapTimer <= 0) ghostTapTimer = 0;
    }

    public function getNotesMayHit():Array<NoteSprite>
    {
        return notes.members.filter(function(note:NoteSprite) {
            return note != null && note.alive && !note.hasBeenHit && note.mayHit;
        });
    }

    public function getHoldNotesHitOrMissed():Array<SustainTrail>
    {
        return holdNotes.members.filter(function(holdNote:SustainTrail) {
            return holdNote != null && holdNote.alive && (holdNote.hitNote || holdNote.missedNote);
        });
    }

    public function getNoteSprite(noteData:SongNoteData):NoteSprite
    {
        if (noteData == null) return null;

        for (note in notes.members)
        {
          if (note == null) continue;
          if (note.alive) continue;
    
          if (note.noteData == noteData) return note;
        }
    
        return null;
    }

    public function getHoldNoteSprite(noteData:SongNoteData):SustainTrail
    {
        if (noteData == null || ((noteData.length ?? 0.0) <= 0.0)) return null;

        for (holdNote in holdNotes.members)
        {
          if (holdNote == null) continue;
          if (holdNote.alive) continue;
    
          if (holdNote.noteData == noteData) return holdNote;
        }
    
        return null;
    }

    public function vwooshNotes():Void
    {
        for (note in notes.members)
        {
            if (note == null || !note.alive) continue;
              notes.remove(note);
              notesVwoosh.add(note);
        
            var targetY:Float = FlxG.height + note.y;
            if (downscroll) targetY = 0 - note.height;
            FlxTween.tween(note, {y: targetY}, 0.5,
            {
                ease: FlxEase.expoIn,
                onComplete: function(twn) {
                    note.kill();
                    notesVwoosh.remove(note, true);
                    note.destroy();
                }
            });
        }
        
        for (holdNote in holdNotes.members)
        {
            if (holdNote == null) continue;
            if (!holdNote.alive) continue;
        
            holdNotes.remove(holdNote);
            holdNotesVwoosh.add(holdNote);
        
            var targetY:Float = FlxG.height + holdNote.y;
            if (downscroll) targetY = 0 - holdNote.height;
            FlxTween.tween(holdNote, {y: targetY}, 0.5,
            {
                ease: FlxEase.expoIn, onComplete: function(twn) {
                    holdNote.kill();
                    holdNotesVwoosh.remove(holdNote, true);
                    holdNote.destroy();
                }
            });
        }        
    }

    public function calculateNoteYPos(strumTime:Float, vwoosh:Bool = true):Float
    {
        var vwoosh:Float = 1.0;

        return Constants.PIXELS_PER_MS * (Conductor.instance.songPosition - strumTime - Conductor.instance.inputOffset) * scrollSpeed * vwoosh * (downscroll ? 1 : -1);
    }

    function updateNotes():Void
    {
        if (noteData.length == 0) return;

        var songStart:Float = PlayState.instance?.startTimestamp ?? 0.0;
        var hitWindowStart:Float = Conductor.instance.songPosition - Constants.HIT_WINDOW_MS;
        var renderWindowStart:Float = Conductor.instance.songPosition + RENDER_DISTANCE_MS;

        for (noteIndex in nextNoteIndex...noteData.length)
        {
            var note:Null<SongNoteData> = noteData[noteIndex];

            if (note == null) continue; // Note is blank
            if (note.time < songStart || note.time < hitWindowStart)
            {
                nextNoteIndex = noteIndex + 1;
                continue;
            }
            if (note.time > renderWindowStart) break;


            var noteSprite = buildNoteSprite(note);

            if (note.length > 0)   noteSprite.holdNoteSprite = buildHoldNoteSprite(note);

            nextNoteIndex = noteIndex + 1; // Increment the nextNoteIndex rather than splicing the array, because splicing is slow.

            onNoteIncoming.dispatch(noteSprite);
        }

        notes.forEachAlive(function(note:NoteSprite)
        {
            var vwoosh:Bool = note.holdNoteSprite == null;
            // Set the note's position.
            note.y = this.y - INITIAL_OFFSET + calculateNoteYPos(note.strumTime, vwoosh);  
            var isOffscreen = downscroll ? note.y > FlxG.height : note.y < -note.height;
            if (note.handledMiss && isOffscreen) killNote(note);
        });

        holdNotes.forEachAlive(function(holdNote:SustainTrail)
        {
            var renderWindowEnd = holdNote.strumTime + holdNote.fullSustainLength + Constants.HIT_WINDOW_MS + RENDER_DISTANCE_MS / 8;

            if (holdNote.missedNote && Conductor.instance.songPosition >= renderWindowEnd)
            {
                holdNote.visible = false;
                holdNote.kill(); // Do not destroy! Recycling is faster.
            }
            else if (holdNote.hitNote && holdNote.sustainLength <= 0)
            {
                playStatic(holdNote.noteDirection);

                if (holdNote.cover != null)
                    holdNote.cover.playEnd();

                holdNote.visible = false;
                holdNote.kill();
            }
            else if (holdNote.missedNote && (holdNote.fullSustainLength > holdNote.sustainLength))
            {
                holdNote.visible = true;

                var yOffset:Float = (holdNote.fullSustainLength - holdNote.sustainLength) * Constants.PIXELS_PER_MS;
        
                var vwoosh:Bool = false;

                if (downscroll)
                    holdNote.y = this.y - INITIAL_OFFSET + calculateNoteYPos(holdNote.strumTime, vwoosh) - holdNote.height + STRUMLINE_SIZE / 2;
                else
                    holdNote.y = this.y - INITIAL_OFFSET + calculateNoteYPos(holdNote.strumTime, vwoosh) + yOffset + STRUMLINE_SIZE / 2;

                if (holdNote.cover != null)
                {
                    holdNote.cover.visible = false;
                    holdNote.cover.kill();
                }
            }
            else if (Conductor.instance.songPosition > holdNote.strumTime && holdNote.hitNote)
            {
                holdConfirm(holdNote.noteDirection);
                holdNote.visible = true;
                holdNote.sustainLength = (holdNote.strumTime + holdNote.fullSustainLength) - Conductor.instance.songPosition;
                if (holdNote.sustainLength <= 10)  holdNote.visible = false;

                if (downscroll)
                    holdNote.y = this.y - INITIAL_OFFSET - holdNote.height + STRUMLINE_SIZE / 2;
                else
                    holdNote.y = this.y - INITIAL_OFFSET + STRUMLINE_SIZE / 2;
            }
            else
            {
                holdNote.visible = true;
                var vwoosh:Bool = false;
        
                if (downscroll)
                    holdNote.y = this.y - INITIAL_OFFSET + calculateNoteYPos(holdNote.strumTime, vwoosh) - holdNote.height + STRUMLINE_SIZE / 2;
                else
                    holdNote.y = this.y - INITIAL_OFFSET + calculateNoteYPos(holdNote.strumTime, vwoosh) + STRUMLINE_SIZE / 2;
            }
        });
    }

    public function getNotesOnScreen():Array<NoteSprite>
    {
        return notes.members.filter(function(note:NoteSprite) {
            return note != null && note.alive && !note.hasBeenHit;
        });
    }
    public function handleSkippedNotes():Void
    {
        for (note in notes.members)
        {
            if (note == null || note.hasBeenHit) continue;
			var hitWindowEnd = note.strumTime + Constants.HIT_WINDOW_MS;
		  
			if (Conductor.instance.songPosition > hitWindowEnd) note.handledMiss = true;
        }

        clean();
        nextNoteIndex = 0;
    }

    public function onBeatHit():Void
    {
        if (notes.members.length > 1) notes.members.insertionSort(compareNoteSprites.bind(FlxSort.ASCENDING));
        if (holdNotes.members.length > 1) holdNotes.members.insertionSort(compareHoldNoteSprites.bind(FlxSort.ASCENDING));
    }

    public function clean():Void
    {
        for (note in notes.members)
        {
            if (note == null) continue;
            killNote(note);
        }
        
        for (holdNote in holdNotes.members)
        {
            if (holdNote == null) continue;
            holdNote.kill();
        }
        
        for (splash in noteSplashes)
        {
            if (splash == null) continue;
            splash.kill();
        }
        
        for (cover in noteHoldCovers)
        {
            if (cover == null) continue;
            cover.kill();
        }

        heldKeys = [false, false, false, false];

        for (dir in DIRECTIONS)
            playStatic(dir);

        resetScrollSpeed();
    }

    public function applyNoteData(data:Array<SongNoteData>):Void
    {
        this.notes.clear();

        this.noteData = data.copy();
        this.nextNoteIndex = 0;

        // Sort the notes by strumtime.
        this.noteData.insertionSort(compareNoteData.bind(FlxSort.ASCENDING));
    }

    public function hitNote(note:NoteSprite, removeNote:Bool = true):Void
    {
        playConfirm(note.direction);
        note.hasBeenHit = true;
    
        if (removeNote) 
            killNote(note);
        else
        {
            note.alpha = 0.5;
            note.desaturate();
        }

        if (note.holdNoteSprite != null)
        {
            note.holdNoteSprite.hitNote = true;
            note.holdNoteSprite.missedNote = false;

            note.holdNoteSprite.sustainLength = (note.holdNoteSprite.strumTime + note.holdNoteSprite.fullSustainLength) - Conductor.instance.songPosition;
        }
    }

    public function killNote(note:NoteSprite):Void
    {
        if (note == null) return;
        note.visible = false;
        notes.remove(note, false);
        note.kill();
    
        if (note.holdNoteSprite != null)
        {
            note.holdNoteSprite.missedNote = true;
            note.holdNoteSprite.visible = false;
        }
    }

    public function getByIndex(index:Int):StrumlineNote
        return this.strumlineNotes.members[index];

    public function getByDirection(direction:NoteDirection):StrumlineNote
        return getByIndex(DIRECTIONS.indexOf(direction));

    public function playStatic(direction:NoteDirection):Void
        getByDirection(direction).playStatic();

    public function playPress(direction:NoteDirection):Void
        getByDirection(direction).playPress();

    public function playConfirm(direction:NoteDirection):Void
        getByDirection(direction).playConfirm();

    public function holdConfirm(direction:NoteDirection):Void
        getByDirection(direction).holdConfirm();

    public function isConfirm(direction:NoteDirection):Bool
        return getByDirection(direction).isConfirm();

    public function playNoteSplash(direction:NoteDirection):Void
    {
        if (!noteStyle.isNoteSplashEnabled()) return;

        var splash:NoteSplash = this.constructNoteSplash();
    
        if (splash != null)
        {
          splash.play(direction);
    
          splash.x = this.x;
          splash.x += getXPos(direction);
          splash.x += INITIAL_OFFSET;

          splash.y = this.y;
          splash.y -= INITIAL_OFFSET;
          splash.y -= 50; // Manual tweaking because fuck.
        }
    }

    public function playNoteHoldCover(holdNote:SustainTrail):Void
    {
        if (!noteStyle.isHoldNoteCoverEnabled()) return;

        var cover:NoteHoldCover = this.constructNoteHoldCover();
    
        if (cover != null)
        {
            cover.holdNote = holdNote;
            holdNote.cover = cover;      
            cover.visible = true;
            cover.playStart();
      
            cover.x = this.x;
            cover.x += getXPos(holdNote.noteDirection);
            cover.x += STRUMLINE_SIZE / 2;
            cover.x -= cover.width / 2;
            cover.x += -12; // Manual tweaking because fuck.
      
            cover.y = this.y;
            cover.y += INITIAL_OFFSET;
            cover.y += STRUMLINE_SIZE / 2;
            cover.y -= 150; // Manual tweaking because fuck.
        }
    }

    public function buildNoteSprite(note:SongNoteData):NoteSprite
    {
        var noteSprite:NoteSprite = constructNoteSprite();

        if (noteSprite != null)
        {
            var noteKindStyle:NoteStyle = NoteKindManager.getNoteStyle(note.kind, this.noteStyle.id) ?? this.noteStyle;
            noteSprite.setupNoteGraphic(noteKindStyle);
      
            noteSprite.direction = note.getDirection();
            //Setup Notetype :/
            switch(note.kind)
            {
                case 'gf':
                    noteSprite.gf = true;
                case 'noAnim':
                    noteSprite.noAnim = true;
                case 'alt':
                    noteSprite.suffix = "-alt";
            }

            noteSprite.noteData = note;
            noteSprite.lane = this.lane;
            noteSprite.x = this.x;
            noteSprite.x += getXPos(DIRECTIONS[note.getDirection() % KEY_COUNT]);
            noteSprite.x -= (noteSprite.width - STRUMLINE_SIZE) / 2; // Center it
            noteSprite.x -= NUDGE;
            noteSprite.y = -9999;
        }
        return noteSprite;
    }

    public function buildHoldNoteSprite(note:SongNoteData):SustainTrail
    {
        var holdNoteSprite:SustainTrail = constructHoldNoteSprite();

        if (holdNoteSprite != null)
        {
            var noteKindStyle:NoteStyle = NoteKindManager.getNoteStyle(note.kind, this.noteStyle.id) ?? this.noteStyle;
            holdNoteSprite.setupHoldNoteGraphic(noteKindStyle);
            holdNoteSprite.flipY = downscroll;
            holdNoteSprite.alpha = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;
            holdNoteSprite.parentStrumline = this;
            holdNoteSprite.noteData = note;
            holdNoteSprite.strumTime = note.time;
            holdNoteSprite.noteDirection = note.getDirection();
            holdNoteSprite.fullSustainLength = note.length;
            holdNoteSprite.sustainLength = note.length;
            holdNoteSprite.missedNote = false;
            holdNoteSprite.hitNote = false;
            holdNoteSprite.visible = true;
            holdNoteSprite.x = this.x;
            holdNoteSprite.x += getXPos(DIRECTIONS[note.getDirection() % KEY_COUNT]);
            holdNoteSprite.x += STRUMLINE_SIZE / 2;
            holdNoteSprite.x -= holdNoteSprite.width / 2;
            holdNoteSprite.y = -9999;
        }
        return holdNoteSprite;
    }

    function constructNoteSplash():NoteSplash
    {
        var result:NoteSplash = null;

        // If we haven't filled the pool yet...
        if (noteSplashes.length < noteSplashes.maxSize)
        {
            result = new NoteSplash();
            this.noteSplashes.add(result);
        }
        else
        {
            result = this.noteSplashes.getFirstAvailable();
            if (result != null)
                result.revive();
            else
                result = FlxG.random.getObject(this.noteSplashes.members);
        }
        return result;
    }

    function constructNoteHoldCover():NoteHoldCover
    {
        var result:NoteHoldCover = null;

        // If we haven't filled the pool yet...
        if (noteHoldCovers.length < noteHoldCovers.maxSize)
        {
            result = new NoteHoldCover();
            this.noteHoldCovers.add(result);
        }
        else
        {
            result = this.noteHoldCovers.getFirstAvailable();

            if (result != null)  
                result.revive();
            else
                result = FlxG.random.getObject(this.noteHoldCovers.members);
        }
        return result;
    }

    function constructNoteSprite():NoteSprite
    {
        var result:NoteSprite = null;

        // Else, find a note which is inactive so we can revive it.
        result = this.notes.getFirstAvailable();
    
        if (result != null)
            result.revive();
        else
        {
            result = new NoteSprite(noteStyle);
            this.notes.add(result);
        }

        return result;
    }

    function constructHoldNoteSprite():SustainTrail
    {
        var result:SustainTrail = null;

        result = this.holdNotes.getFirstAvailable();

        if (result != null)
            result.revive();
        else
        {
            result = new SustainTrail(0, 0, noteStyle);
            this.holdNotes.add(result);
        }

        return result;
    }

    function getXPos(direction:NoteDirection):Float
    {
        return switch (direction)
        {
            case NoteDirection.LEFT: 0;
            case NoteDirection.DOWN: 0 + (1 * NOTE_SPACING);
            case NoteDirection.UP: 0 + (2 * NOTE_SPACING);
            case NoteDirection.RIGHT: 0 + (3 * NOTE_SPACING);
            default: 0;
        }
    }

    function fadeInArrow(index:Int, arrow:StrumlineNote):Void
    {
        arrow.y -= 10;
        arrow.alpha = 0.0;
        FlxTween.tween(arrow, {y: arrow.y + 10, alpha: StrumlineNote.setAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * index)});
    }

    public function fadeInArrows():Void
    {
        for (index => arrow in this.strumlineNotes.members.keyValueIterator())
            fadeInArrow(index, arrow);
    }

    public static function compareNoteData(order:Int, a:SongNoteData, b:SongNoteData):Int
        return FlxSort.byValues(order, a.time, b.time);

    public static function compareNoteSprites(order:Int, a:NoteSprite, b:NoteSprite):Int
        return FlxSort.byValues(order, a?.strumTime, b?.strumTime);

    public static function compareHoldNoteSprites(order:Int, a:SustainTrail, b:SustainTrail):Int
        return FlxSort.byValues(order, a?.strumTime, b?.strumTime);

    public function pressKey(dir:NoteDirection):Void
        heldKeys[dir] = true;

    public function releaseKey(dir:NoteDirection):Void
        heldKeys[dir] = false;

    public function isKeyHeld(dir:NoteDirection):Bool return heldKeys[dir];

}