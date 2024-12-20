package meta.state.editors.charting.commands;

/**
 * Command that deselects all selected notes and events in the chart editor.
 */
@:nullSafety
@:access(meta.state.editors.charting.ChartEditorState)
class DeselectAllItemsCommand implements ChartEditorCommand
{
  var previousNoteSelection:Array<SongNoteData> = [];
  var previousEventSelection:Array<SongEventData> = [];

  public function new() {}

  public function execute(state:ChartEditorState):Void
  {
    this.previousNoteSelection = state.currentNoteSelection;
    this.previousEventSelection = state.currentEventSelection;

    state.currentNoteSelection = [];
    state.currentEventSelection = [];

    state.noteDisplayDirty = true;
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentNoteSelection = previousNoteSelection;
    state.currentEventSelection = previousEventSelection;

    state.noteDisplayDirty = true;
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (previousNoteSelection.length > 0 || previousEventSelection.length > 0);
  }

  public function toString():String
  {
    return 'Deselect All Items';
  }
}
