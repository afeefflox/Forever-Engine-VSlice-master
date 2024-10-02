package gameObjects.userInterface.notes;

class NoteHoldCover extends FlxTypedSpriteGroup<FunkinSprite>
{
    static var glowFrames:FlxFramesCollection;

    public var holdNote:SustainTrail;
  
    var glow:FunkinSprite;

    public function new()
    {
        super(0, 0);

        setup();        
    }

    function setup():Void
    {
        glow = new FunkinSprite();
        add(glow);

        var atlas:FlxFramesCollection = Paths.getSparrowAtlas('noteskins/notes/base/holdCover');
        atlas.parent.persist = true;
        glow.frames = atlas;
        this.alpha = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;
        for (direction in Strumline.DIRECTIONS)
        {
            var directionName = direction.colorName;

            glow.animation.addByPrefix('holdCoverStart$directionName', 'holdCoverStart${directionName}0', 24, false);
            glow.animation.addByPrefix('holdCover$directionName', 'holdCover${directionName}0', 24, true);
            glow.animation.addByPrefix('holdCoverEnd$directionName', 'holdCoverEnd${directionName}0', 24, false);
        }

        glow.animation.finishCallback = this.onAnimationFinished;

        if (glow.animation.getAnimationList().length < 3 * 4)
        {
          trace('WARNING: NoteHoldCover failed to initialize all animations.');
        }
    }

    public function playStart():Void
    {
        var direction:NoteDirection = holdNote.noteDirection;
        glow.animation.play('holdCoverStart${direction.colorName}');
    }
      
    public function playContinue():Void
    {
        var direction:NoteDirection = holdNote.noteDirection;
        glow.animation.play('holdCover${direction.colorName}');
    }
      
    public function playEnd():Void
    {
        var direction:NoteDirection = holdNote.noteDirection;
        glow.animation.play('holdCoverEnd${direction.colorName}');
    }

    public override function kill():Void
    {
        super.kill();

        this.visible = false;
    
        if (glow != null) glow.visible = false;
    }

    public override function revive():Void
    {
        super.revive();

        this.visible = true;
        this.alpha = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;
    
        if (glow != null) glow.visible = true;
    }

    public function onAnimationFinished(animationName:String):Void
    {
        if (animationName.startsWith('holdCoverStart'))
            playContinue();
        if (animationName.startsWith('holdCoverEnd'))
        {
            // *lightning* *zap* *crackle*
            this.visible = false;
            this.kill();
        }
    }
}