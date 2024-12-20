package meta.state.editors.charting.contextmenus;

import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Screen;
import meta.state.editors.charting.commands.RemoveEventsCommand;

@:access(meta.state.editors.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/ui/chart-editor/context-menus/event.xml"))
class ChartEditorEventContextMenu extends ChartEditorBaseContextMenu
{
  var contextmenuEdit:MenuItem;
  var contextmenuDelete:MenuItem;

  var data:SongEventData;

  public function new(chartEditorState2:ChartEditorState, xPos2:Float = 0, yPos2:Float = 0, data:SongEventData)
  {
    super(chartEditorState2, xPos2, yPos2);
    this.data = data;

    initialize();
  }

  function initialize()
  {
    contextmenuEdit.onClick = function(_) {
      chartEditorState.showToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT);
    }

    contextmenuDelete.onClick = function(_) {
      chartEditorState.performCommand(new RemoveEventsCommand([data]));
    }
  }
}
