package gameObjects.userInterface.notes;

import gameObjects.userInterface.notes.notestyle.NoteStyle;

class StrumlineNote extends FunkinSprite
{
    public var isPlayer(default, null):Bool;

    public var direction(default, set):NoteDirection;
  
    var confirmHoldTimer:Float = -1;
  
    static final CONFIRM_HOLD_TIME:Float = 0.1;

    public static var setAlpha:Float = (Init.trueSettings.get('Opaque Arrows')) ? 1 : 0.8;
  
    function set_direction(value:NoteDirection):NoteDirection
    {
        this.direction = value;
        return this.direction;
    }

    public function new(noteStyle:NoteStyle, direction:NoteDirection)
    {
        super(0, 0);
        this.direction = direction;
        setup(noteStyle);
        this.animation.finishCallback = onAnimationFinished;
    
        // Must be true for animations to play.
        this.active = true;
    }

    function onAnimationFinished(name:String):Void
    {
        if (name == 'confirm')   confirmHoldTimer = 0;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        centerOrigin();
    
        if (confirmHoldTimer >= 0)
        {
          confirmHoldTimer += elapsed;
    
          // Ensure the opponent stops holding the key after a certain amount of time.
          if (confirmHoldTimer >= CONFIRM_HOLD_TIME)
          {
            confirmHoldTimer = -1;
            playStatic();
          }
        }
    }

    function setup(noteStyle:NoteStyle):Void
    {
        if (noteStyle == null)
         {
            // If you get an exception on this line, check the debug console.
            // You probably have a parsing error in your note style's JSON file.
            throw "FATAL ERROR: Attempted to initialize PlayState with an invalid NoteStyle.";
        }
        
        noteStyle.applyStrumlineFrames(this);
        noteStyle.applyStrumlineAnimations(this, this.direction);
        
        this.setGraphicSize(Std.int(Strumline.STRUMLINE_SIZE * noteStyle.getStrumlineScale()));
        this.updateHitbox();
        noteStyle.applyStrumlineOffsets(this);
        
        this.playStatic();
    }

    public function playAnimation(name:String = 'static', force:Bool = false, reversed:Bool = false, startFrame:Int = 0):Void
    {
        this.animation.play(name, force, reversed, startFrame);

        centerOffsets();
        centerOrigin();
    }

    public function playStatic():Void
    {
        this.active = false;
        this.alpha = setAlpha;
        this.playAnimation('static', true);
    }
      
    public function playPress():Void
    {
        this.active = true;
        this.alpha = setAlpha;
        this.playAnimation('press', true);
    }

    public function playConfirm():Void
    {
        this.active = true;
        this.alpha = 1;
        this.playAnimation('confirm', true);
    }

    public function isConfirm():Bool
        return getCurrentAnimation().startsWith('confirm');

    public function holdConfirm():Void
    {
        this.active = true;

        if (getCurrentAnimation() == "confirm-hold")
            return;
        else if (getCurrentAnimation() == "confirm")
        {
            if (isAnimationFinished())
            {
                this.confirmHoldTimer = -1;
                this.playAnimation('confirm-hold', false, false);
            }
        }
        else
            this.playAnimation('confirm', false, false);
    }

    public function getCurrentAnimation():String
    {
        if (this.animation == null || this.animation.curAnim == null) return "";
        return this.animation.curAnim.name;
    }

    public function isAnimationFinished():Bool
        return this.animation.finished;

    static final DEFAULT_OFFSET:Int = 13;
    function fixOffsets():Void
    {
        this.centerOffsets();

        if (getCurrentAnimation() == "confirm")
        {
            this.offset.x -= DEFAULT_OFFSET;
            this.offset.y -= DEFAULT_OFFSET;
        }
        else
            this.centerOrigin();
    }
}