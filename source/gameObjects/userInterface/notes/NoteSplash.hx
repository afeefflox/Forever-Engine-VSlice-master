package gameObjects.userInterface.notes;

class NoteSplash extends FunkinSprite
{
    static final ALPHA:Float = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;
    static final FRAMERATE_DEFAULT:Int = 24;
    static final FRAMERATE_VARIANCE:Int = 2;

    static var frameCollection:FlxFramesCollection;

    public static function preloadFrames():Void
    {
        frameCollection = Paths.getSparrowAtlas('noteskins/notes/base/noteSplashes');
        frameCollection.parent.persist = true;
    }

    public function new()
    {
        super(0, 0);

        setup();
    
        this.alpha = ALPHA;
        this.animation.finishCallback = this.onAnimationFinished;
    }

    function setup():Void
    {
        if (frameCollection?.parent?.isDestroyed ?? false) frameCollection = null;
        if (frameCollection == null) preloadFrames();
    
        this.frames = frameCollection;
    
        this.animation.addByPrefix('splash1Left', 'note impact 1 purple0', FRAMERATE_DEFAULT, false);
        this.animation.addByPrefix('splash1Down', 'note impact 1  blue0', FRAMERATE_DEFAULT, false);
        this.animation.addByPrefix('splash1Up', 'note impact 1 green0', FRAMERATE_DEFAULT, false);
        this.animation.addByPrefix('splash1Right', 'note impact 1 red0', FRAMERATE_DEFAULT, false);
        this.animation.addByPrefix('splash2Left', 'note impact 2 purple0', FRAMERATE_DEFAULT, false);
        this.animation.addByPrefix('splash2Down', 'note impact 2 blue0', FRAMERATE_DEFAULT, false);
        this.animation.addByPrefix('splash2Up', 'note impact 2 green0', FRAMERATE_DEFAULT, false);
        this.animation.addByPrefix('splash2Right', 'note impact 2 red0', FRAMERATE_DEFAULT, false);
    
        if (this.animation.getAnimationList().length < 8)
        {
          trace('WARNING: NoteSplash failed to initialize all animations.');
        }
    }

    public function playAnim(name:String, force:Bool = false, reversed:Bool = false, startFrame:Int = 0):Void
        this.animation.play(name, force, reversed, startFrame);
      
    public function play(direction:NoteDirection, variant:Int = null):Void
    {
        if (variant == null) variant = FlxG.random.int(1, 2);
      
        switch (direction)
        {
            case NoteDirection.LEFT:
              this.playAnim('splash${variant}Left');
            case NoteDirection.DOWN:
              this.playAnim('splash${variant}Down');
            case NoteDirection.UP:
              this.playAnim('splash${variant}Up');
            case NoteDirection.RIGHT:
              this.playAnim('splash${variant}Right');
        }
      
        if (animation.curAnim == null) return;
      
        // Vary the speed of the animation a bit.
        animation.curAnim.frameRate = FRAMERATE_DEFAULT + FlxG.random.int(-FRAMERATE_VARIANCE, FRAMERATE_VARIANCE);
      
        // Center the animation on the note splash.
        offset.set(width * 0.3, height * 0.3);
    }
      
    public function onAnimationFinished(animationName:String):Void
    {
        // *lightning* *zap* *crackle*
        this.kill();
    }
}