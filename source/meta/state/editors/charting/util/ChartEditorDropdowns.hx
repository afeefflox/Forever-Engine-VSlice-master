package meta.state.editors.charting.util;

import haxe.ui.components.DropDown;

/**
 * Functions for populating dropdowns based on game data.
 * These get used by both dialogs and toolboxes so they're in their own class to prevent "reaching over."
 */
@:nullSafety
@:access(meta.state.editors.charting.ChartEditorState)
class ChartEditorDropdowns
{
  /**
   * Populate a dropdown with a list of characters.
   */
  public static function populateDropdownWithCharacters(dropDown:DropDown, charType:CharacterType, startingCharId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    // TODO: Filter based on charType.
    var charIds:Array<String> = CharacterRegistry.listCharacterIds();

    var returnValue:DropDownEntry = switch (charType)
    {
      case BF: {id: "bf", text: "Boyfriend"};
      case DAD: {id: "dad", text: "Daddy Dearest"};
      default: {
          dropDown.dataSource.add({id: "none", text: ""});
          {id: "none", text: "None"};
        }
    }

    for (charId in charIds)
    {
      var character:Null<CharacterData> = CharacterRegistry.fetchCharacterData(charId);
      if (character == null) continue;

      var value = {id: charId, text: character.name};
      if (startingCharId == charId) returnValue = value;

      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }

  /**
   * Populate a dropdown with a list of stages.
   */
  public static function populateDropdownWithStages(dropDown:DropDown, startingStageId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    var stageIds:Array<String> = StageRegistry.instance.listEntryIds();

    var returnValue:DropDownEntry = {id: "mainStage", text: "Main Stage"};

    for (stageId in stageIds)
    {
      var stage:Null<Stage> = StageRegistry.instance.fetchEntry(stageId);
      if (stage == null) continue;

      var value = {id: stage.id, text: stage.stageName};
      if (startingStageId == stageId) returnValue = value;

      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }

  public static function populateDropdownWithSongEvents(dropDown:DropDown, startingEventId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    var returnValue:DropDownEntry = {id: "FocusCamera", text: "Focus Camera"};

    var songEvents:Array<SongEvent> = SongEventRegistry.listEvents();

    for (event in songEvents)
    {
      var value = {id: event.id, text: event.getTitle()};
      if (startingEventId == event.id) returnValue = value;
      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }

  /**
   * Given the ID of a dropdown element, find the corresponding entry in the dropdown's dataSource.
   */
  public static function findDropdownElement(id:String, dropDown:DropDown):Null<DropDownEntry>
  {
    // Attempt to find the entry.
    for (entryIndex in 0...dropDown.dataSource.size)
    {
      var entry = dropDown.dataSource.get(entryIndex);
      if (entry.id == id) return entry;
    }

    // Not found.
    return null;
  }

  /**
   * Populate a dropdown with a list of note styles.
   */
  public static function populateDropdownWithNoteStyles(dropDown:DropDown, startingStyleId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    var noteStyleIds:Array<String> = NoteStyleRegistry.instance.listEntryIds();

    var returnValue:DropDownEntry = {id: "base", text: "Funkin'"};

    for (noteStyleId in noteStyleIds)
    {
      var noteStyle:Null<NoteStyle> = NoteStyleRegistry.instance.fetchEntry(noteStyleId);
      if (noteStyle == null) continue;

      // check if the note style has all necessary assets (strums, notes, holdNotes)
      if (noteStyle._data?.assets?.noteStrumline == null
        || noteStyle._data?.assets?.note == null
        || noteStyle._data?.assets?.holdNote == null)
      {
        continue;
      }

      var value = {id: noteStyleId, text: noteStyle.getName()};
      if (startingStyleId == noteStyleId) returnValue = value;

      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }

  public static final NOTE_KINDS:Map<String, String> = [
    // Base
    "" => "Default",
    "~CUSTOM~" => "Custom",
    "alt" => "Alternative Note",
    "gf" => "Girlfriend Sing",
    "noAnim" => "No Animation"
  ];

  public static function populateDropdownWithNoteKinds(dropDown:DropDown, startingKindId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    var returnValue:DropDownEntry = lookupNoteKind('');

    for (noteKindId in NOTE_KINDS.keys())
    {
      var noteKind:String = NOTE_KINDS.get(noteKindId) ?? 'Unknown';

      var value:DropDownEntry = {id: noteKindId, text: noteKind};
      if (startingKindId == noteKindId) returnValue = value;

      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('id', ASCENDING);

    return returnValue;
  }

  public static function lookupNoteKind(noteKindId:Null<String>):DropDownEntry
  {
    if (noteKindId == null) return lookupNoteKind('');
    if (!NOTE_KINDS.exists(noteKindId)) return {id: '~CUSTOM~', text: 'Custom'};
    return {id: noteKindId ?? '', text: NOTE_KINDS.get(noteKindId) ?? 'Unknown'};
  }

  /**
   * Populate a dropdown with a list of song variations.
   */
  public static function populateDropdownWithVariations(dropDown:DropDown, state:ChartEditorState, includeNone:Bool = true):DropDownEntry
  {
    dropDown.dataSource.clear();

    var variationIds:Array<String> = state.availableVariations;

    if (includeNone)
    {
      dropDown.dataSource.add({id: "none", text: ""});
    }

    var returnValue:DropDownEntry = includeNone ? ({id: "none", text: ""}) : ({id: "default", text: "Default"});

    for (variationId in variationIds)
    {
      dropDown.dataSource.add({id: variationId, text: variationId.toTitleCase()});
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }
}

/**
 * An entry in a dropdown.
 */
typedef DropDownEntry =
{
  id:String,
  text:String
};
