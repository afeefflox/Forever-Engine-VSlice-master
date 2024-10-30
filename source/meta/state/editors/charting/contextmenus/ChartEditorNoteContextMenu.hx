package meta.state.editors.charting.contextmenus;

import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Screen;
import meta.state.editors.charting.commands.FlipNotesCommand;
import meta.state.editors.charting.commands.RemoveNotesCommand;
import meta.state.editors.charting.commands.ExtendNoteLengthCommand;
import meta.state.editors.charting.commands.SetKindNotesCommand;
@:access(meta.state.editors.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/ui/chart-editor/context-menus/note.xml"))
class ChartEditorNoteContextMenu extends ChartEditorBaseContextMenu
{
  var contextmenuKind:MenuItem;
  var contextmenuFlip:MenuItem;
  var contextmenuDelete:MenuItem;

  var data:SongNoteData;

  public function new(chartEditorState2:ChartEditorState, xPos2:Float = 0, yPos2:Float = 0, data:SongNoteData)
  {
    super(chartEditorState2, xPos2, yPos2);
    this.data = data;

    initialize();
  }

  function initialize():Void
  {
    // NOTE: Remember to use commands here to ensure undo/redo works properly
    contextmenuFlip.onClick = function(_) {
      chartEditorState.performCommand(new FlipNotesCommand([data]));
    }

    contextmenuKind.onClick = function(_) {
      chartEditorState.performCommand(new SetKindNotesCommand([data], chartEditorState.noteKindToPlace));
    }

    contextmenuAddHold.onClick = function(_) {
      chartEditorState.performCommand(new ExtendNoteLengthCommand(data, 4, STEPS));
    }

    contextmenuDelete.onClick = function(_) {
      chartEditorState.performCommand(new RemoveNotesCommand([data]));
    }
  }
}
