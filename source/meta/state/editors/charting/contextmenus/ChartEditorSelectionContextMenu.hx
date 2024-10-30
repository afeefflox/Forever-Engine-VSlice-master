package meta.state.editors.charting.contextmenus;

import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Screen;
import meta.state.editors.charting.commands.CutItemsCommand;
import meta.state.editors.charting.commands.RemoveEventsCommand;
import meta.state.editors.charting.commands.RemoveItemsCommand;
import meta.state.editors.charting.commands.RemoveNotesCommand;
import meta.state.editors.charting.commands.SetKindNotesCommand;
@:access(meta.state.editors.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/ui/chart-editor/context-menus/selection.xml"))
class ChartEditorSelectionContextMenu extends ChartEditorBaseContextMenu
{
  var contextmenuCut:MenuItem;
  var contextmenuCopy:MenuItem;
  var contextmenuPaste:MenuItem;
  var contextmenuDelete:MenuItem;
  var contextmenuFlip:MenuItem;
  var contextmenuKind:MenuItem;
  var contextmenuSelectAll:MenuItem;
  var contextmenuSelectInverse:MenuItem;
  var contextmenuSelectNone:MenuItem;

  public function new(chartEditorState2:ChartEditorState, xPos2:Float = 0, yPos2:Float = 0)
  {
    super(chartEditorState2, xPos2, yPos2);

    initialize();
  }

  function initialize():Void
  {
    contextmenuCut.onClick = (_) -> {
      chartEditorState.performCommand(new CutItemsCommand(chartEditorState.currentNoteSelection, chartEditorState.currentEventSelection));
    };
    contextmenuCopy.onClick = (_) -> {
      chartEditorState.copySelection();
    };
    contextmenuKind.onClick = (_) -> {chartEditorState.performCommand(new SetKindNotesCommand(chartEditorState.currentNoteSelection, chartEditorState.noteKindToPlace));};
    contextmenuFlip.onClick = (_) -> {
      if (chartEditorState.currentNoteSelection.length > 0 && chartEditorState.currentEventSelection.length > 0)
      {
        chartEditorState.performCommand(new RemoveItemsCommand(chartEditorState.currentNoteSelection, chartEditorState.currentEventSelection));
      }
      else if (chartEditorState.currentNoteSelection.length > 0)
      {
        chartEditorState.performCommand(new RemoveNotesCommand(chartEditorState.currentNoteSelection));
      }
      else if (chartEditorState.currentEventSelection.length > 0)
      {
        chartEditorState.performCommand(new RemoveEventsCommand(chartEditorState.currentEventSelection));
      }
      else
      {
        // Do nothing???
      }
    };
  }
}
