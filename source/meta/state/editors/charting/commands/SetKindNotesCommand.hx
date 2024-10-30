package meta.state.editors.charting.commands;

@:nullSafety
@:access(meta.state.editors.charting.ChartEditorState)
class SetKindNotesCommand implements ChartEditorCommand
{
    var notes:Array<SongNoteData> = [];
    var kindedNotes:Array<SongNoteData> = [];

    public function new(notes:Array<SongNoteData>, noteKindToPlace:String)
    {
        this.notes = notes;
        this.kindedNotes = SongDataUtils.setKindNotes(notes, noteKindToPlace);
    }

    public function execute(state:ChartEditorState):Void
    {
        state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
        state.currentSongChartNoteData = state.currentSongChartNoteData.concat(kindedNotes);
        state.currentNoteSelection = kindedNotes;
        state.currentEventSelection = [];
        state.saveDataDirty = true;
        state.noteDisplayDirty = true;
        state.notePreviewDirty = true;
        state.sortChartData();
    }

    public function undo(state:ChartEditorState):Void
    {
        state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, kindedNotes);
        state.currentSongChartNoteData = state.currentSongChartNoteData.concat(notes);
        state.currentNoteSelection = notes;
        state.currentEventSelection = [];
    
        state.saveDataDirty = true;
        state.noteDisplayDirty = true;
        state.notePreviewDirty = true;
    
        state.sortChartData();
    }

    public function shouldAddToHistory(state:ChartEditorState):Bool
    {
        return (notes.length > 0);
    }

    public function toString():String
    {
        return 'Switch Note kind ${notes[0].kind}';
    }
}