package meta.state.editors.charting.contextmenus;

import haxe.ui.containers.menus.Menu;

@:access(meta.state.editors.charting.ChartEditorState)
class ChartEditorBaseContextMenu extends Menu
{
  var chartEditorState:ChartEditorState;

  public function new(chartEditorState:ChartEditorState, xPos:Float = 0, yPos:Float = 0)
  {
    super();

    this.chartEditorState = chartEditorState;

    this.left = xPos;
    this.top = yPos;
  }
}
