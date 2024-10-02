package gameObjects.userInterface.notes;

import flixel.FlxSprite;
import graphics.FunkinSprite;
import graphics.shaders.HSVShader;

class NoteSprite extends FunkinSprite
{
    public var holdNoteSprite:SustainTrail;

    var DIRECTION_COLORS:Array<String> = ['purple', 'blue', 'green', 'red'];

    var hsvShader:HSVShader = new HSVShader();

    public var strumTime(get, set):Float;

    function get_strumTime():Float
        return this.noteData?.time ?? 0.0;

    function set_strumTime(value:Float):Float
    {
        if (this.noteData == null) return value;
        return this.noteData.time = value;
    }

    public var length(get, set):Float;

    function get_length():Float
        return this.noteData?.length ?? 0.0;

    function set_length(value:Float):Float
    {
        if (this.noteData == null) return value;
        return this.noteData.length = value;
    }

    public var kind(get, set):Null<String>;

    function get_kind():Null<String>
        return this.noteData?.kind;

    function set_kind(value:String):String
    {
        if (this.noteData == null) return value;
        return this.noteData.kind = value;
    }

    public var direction(default, set):NoteDirection;

    function set_direction(value:Int):Int
    {
        if (frames == null) return value;

        playNoteAnimation(value);
    
        this.direction = value;
        return this.direction;
    }

    public var data(get, never):Int;
    function get_data():Int
        return noteData.getDirection();

    public var noteData:NoteJson;

    public var isHoldNote(get, never):Bool;
    function get_isHoldNote():Bool
        return noteData.length > 0;        

    public var hasBeenHit:Bool = false;
    public var lowPriority:Bool = false;
    public var hasMissed:Bool;
    public var tooEarly:Bool;
    public var mayHit:Bool;
    public var handledMiss:Bool;
    public var ignore:Bool = false;
    public var gf:Bool = false;
    public var noAnim:Bool = false;
    public var suffix:String = "";
    public var lane:Int = 0;

    public function new(noteStyle:NoteStyle, direction:Int = 0)
    {
        super(0, -9999);

        this.direction = direction;
        setupNoteGraphic(noteStyle);
    }

    public function setupNoteGraphic(noteStyle:NoteStyle):Void
    {
        noteStyle.buildNoteSprite(this);
        this.shader = hsvShader;
        this.active = noteStyle.isNoteAnimated();
    }

    function playNoteAnimation(value:Int):Void
    {
        animation.play(DIRECTION_COLORS[value] + 'Scroll');
    }

    public function desaturate():Void
        this.hsvShader.saturation = 0.2;

    public function setHue(hue:Float):Void
        this.hsvShader.hue = hue;

    public override function revive():Void
        {
          super.revive();
          this.visible = true;
          this.alpha = 1.0;
          this.active = false;
          this.tooEarly = false;
          this.hasBeenHit = false;
          this.mayHit = false;
          this.hasMissed = false;
      
          this.hsvShader.hue = 1.0;
          this.hsvShader.saturation = 1.0;
          this.hsvShader.value = 1.0;
        }
}