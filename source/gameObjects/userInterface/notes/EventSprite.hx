package gameObjects.userInterface.notes;

import flixel.FlxSprite;
import graphics.FunkinSprite;
import graphics.shaders.HSVShader;

//Nothing personal :/
class EventSprite extends FunkinSprite
{
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

    public var name(get, set):String;

    function get_name():String
        return this.noteData?.name ?? "";

    function set_name(value:String):String
    {
        if (this.noteData == null) return value;
        return this.noteData.name = value;
    }

    public var values(get, set):Null<Array<Dynamic>>;

    function get_values():Null<Array<Dynamic>>
        return this.noteData?.values;

    function set_values(value:Array<Dynamic>):Array<Dynamic>
    {
        if (this.noteData == null) return value;
        return this.noteData.values = value;
    }

    public var direction(default, set):NoteDirection;

    function set_direction(value:Int):Int
    {
        if (frames == null) return value;

        playNoteAnimation(value);
    
        this.direction = value;
        return this.direction;
    }

    public var noteData:EventJson;

    public var eventData:Array<SwagEvent>;

    public function new(noteStyle:NoteStyle, direction:Int = 0)
    {
        super(0, -9999);

        this.direction = direction;
        setupNoteGraphic(noteStyle);
    }

    public function setupNoteGraphic(noteStyle:NoteStyle):Void
    {
        noteStyle.buildEventSprite(this);
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
    
        this.hsvShader.hue = 1.0;
        this.hsvShader.saturation = 1.0;
        this.hsvShader.value = 1.0;
    }
}