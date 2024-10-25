package meta.state.editors.content;

class SustainEditor extends SustainTrail
{
    public function new(noteDirection:NoteDirection, sustainLength:Float, noteStyle:NoteStyle)
    {
        super(noteDirection, sustainLength, noteStyle);
    }

    override function setupHoldNoteGraphic(noteStyle:NoteStyle):Void
    {
        var graphicPath = noteStyle.getHoldNoteAssetPath();
        if (graphicPath == null) return;
        loadGraphic(graphicPath);
    
        antialiasing = true;
    
        this.isPixel = noteStyle.isHoldNotePixel();
        if (isPixel)
        {
          endOffset = bottomClip = 1;
          antialiasing = false;
        }
        else
        {
          endOffset = 0.5;
          bottomClip = 0.9;
        }
    
        zoom = 1.0;
        zoom *= noteStyle.fetchHoldNoteScale();
        zoom *= 0.7;
        zoom *= ChartingState.GRID_SIZE / Strumline.STRUMLINE_SIZE;
    
        graphicWidth = graphic.width / 8 * zoom; // amount of notes * 2
        graphicHeight = sustainLength * 0.45; // sustainHeight

        updateColorTransform();
        updateClipping();
    }

    public override function updateHitbox():Void
    {
        width = ChartingState.GRID_SIZE;
        height = graphicHeight;
    
        var xOffset = (ChartingState.GRID_SIZE - graphicWidth) / 2;
        offset.set(-xOffset, 0);
        origin.set(width * 0.5, height * 0.5);
    }
}