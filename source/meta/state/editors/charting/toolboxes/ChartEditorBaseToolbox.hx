package meta.state.editors.charting.toolboxes;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.core.Component;

/**
 * The base class for the Toolboxes (manipulatable, arrangeable control windows) in the Chart Editor.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(meta.state.editors.charting.ChartEditorState)
class ChartEditorBaseToolbox extends CollapsibleDialog
{
  var chartEditorState:ChartEditorState;

  private function new(chartEditorState:ChartEditorState)
  {
    super();

    this.chartEditorState = chartEditorState;
  }

  /**
   * Override to implement this.
   */
  public function refresh() {}
}
