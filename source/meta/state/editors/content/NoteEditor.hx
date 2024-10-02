package meta.state.editors.content;

class NoteEditor extends FunkinSprite
{
    public var strumTime:Float = 0;
    public var noteData(default, set):Int = 0;
    public var mustPress:Bool = false;
    public var kind:String = "default";
    public var sustainLength:Float = 0;
    public var eventData:Array<SwagEvent> = [];

    var DIRECTION_COLORS:Array<String> = ['purple', 'blue', 'green', 'red'];

    public function new(noteStyle:NoteStyle)
    {
        super(0, -2000);

        setupNoteGraphic(noteStyle);
    }

    function set_noteData(value:Int):Int
    {
        if (frames == null) return value;

        animation.play(DIRECTION_COLORS[value] + 'Scroll');
    
        this.noteData = value;

        return this.noteData;
    }

    public function setupNoteGraphic(noteStyle:NoteStyle):Void
    {
        noteStyle.buildNoteEditorSprite(this);
        this.active = noteStyle.isNoteAnimated();
    }
}