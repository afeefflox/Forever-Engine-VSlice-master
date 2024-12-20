package meta.state.editors.charting.handlers;

import meta.state.editors.charting.contextmenus.ChartEditorDefaultContextMenu;
import meta.state.editors.charting.contextmenus.ChartEditorEventContextMenu;
import meta.state.editors.charting.contextmenus.ChartEditorHoldNoteContextMenu;
import meta.state.editors.charting.contextmenus.ChartEditorNoteContextMenu;
import meta.state.editors.charting.contextmenus.ChartEditorSelectionContextMenu;
import haxe.ui.containers.menus.Menu;
import haxe.ui.core.Screen;

/**
 * Handles context menus (the little menus that appear when you right click on stuff) for the new Chart Editor.
 */
@:nullSafety
@:access(meta.state.editors.charting.ChartEditorState)
class ChartEditorContextMenuHandler
{
  static var existingMenus:Array<Menu> = [];

  public static function openDefaultContextMenu(state:ChartEditorState, xPos:Float, yPos:Float)
  {
    displayMenu(state, new ChartEditorDefaultContextMenu(state, xPos, yPos));
  }

  /**
   * Opened when shift+right-clicking a selection of multiple items.
   */
  public static function openSelectionContextMenu(state:ChartEditorState, xPos:Float, yPos:Float)
  {
    displayMenu(state, new ChartEditorSelectionContextMenu(state, xPos, yPos));
  }

  /**
   * Opened when shift+right-clicking a single note.
   */
  public static function openNoteContextMenu(state:ChartEditorState, xPos:Float, yPos:Float, data:SongNoteData)
  {
    displayMenu(state, new ChartEditorNoteContextMenu(state, xPos, yPos, data));
  }

  /**
   * Opened when shift+right-clicking a single hold note.
   */
  public static function openHoldNoteContextMenu(state:ChartEditorState, xPos:Float, yPos:Float, data:SongNoteData)
  {
    displayMenu(state, new ChartEditorHoldNoteContextMenu(state, xPos, yPos, data));
  }

  /**
   * Opened when shift+right-clicking a single event.
   */
  public static function openEventContextMenu(state:ChartEditorState, xPos:Float, yPos:Float, data:SongEventData)
  {
    displayMenu(state, new ChartEditorEventContextMenu(state, xPos, yPos, data));
  }

  static function displayMenu(state:ChartEditorState, targetMenu:Menu)
  {
    // Close any existing menus
    closeAllMenus(state);

    // Show the new menu
    Screen.instance.addComponent(targetMenu);
    existingMenus.push(targetMenu);
  }

  public static function closeMenu(state:ChartEditorState, targetMenu:Menu)
  {
    // targetMenu.close();
    existingMenus.remove(targetMenu);
  }

  public static function closeAllMenus(state:ChartEditorState)
  {
    for (existingMenu in existingMenus)
    {
      closeMenu(state, existingMenu);
    }
  }
}
