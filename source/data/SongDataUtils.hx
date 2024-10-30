package data;

import flixel.util.FlxSort;

class SongDataUtils
{
    public static function offsetSongNoteData(notes:Array<SongNoteData>, offset:Float):Array<SongNoteData>
    {
        return notes.map(function(note:SongNoteData):SongNoteData {
            return new SongNoteData(note.time + offset, note.data, note.kind);
        });
    }

    public static function offsetSongEventData(events:Array<SongEventData>, offset:Float):Array<SongEventData>
    {
        return events.map(function(event:SongEventData):SongEventData {
            return new SongEventData(event.time + offset, event.eventKind, event.value);
        });
    }

    public static function clampSongNoteData(notes:Array<SongNoteData>, startTime:Float, endTime:Float):Array<SongNoteData>
    {
        return notes.filter(function(note:SongNoteData):Bool {
            return note.time >= startTime && note.time <= endTime;
        });
    }

    public static function clampSongEventData(events:Array<SongEventData>, startTime:Float, endTime:Float):Array<SongEventData>
    {
        return events.filter(function(event:SongEventData):Bool {
            return event.time >= startTime && event.time <= endTime;
        });
    }

    public static function subtractNotes(notes:Array<SongNoteData>, subtrahend:Array<SongNoteData>)
    {
        if (notes.length == 0 || subtrahend.length == 0) return notes;

        var result = notes.filter(function(note:SongNoteData):Bool {
            for (x in subtrahend) if (x == note) return false;
            return true;
        });
        return result;
    }

    public static function subtractEvents(events:Array<SongEventData>, subtrahend:Array<SongEventData>)
    {
        if (events.length == 0 || subtrahend.length == 0) return events;

        return events.filter(function(event:SongEventData):Bool {
            for (x in subtrahend) if (x == event) return false;
            return true;
        });
    }

    public static function flipNotes(notes:Array<SongNoteData>, ?strumline:Int = 4):Array<SongNoteData>
    {
        return notes.map(function(note:SongNoteData):SongNoteData {
            var newData = note.data;
      
            if (newData < 4) 
                newData += 4;
            else
                newData -= 4;
      
            return new SongNoteData(note.time, newData, note.length, note.kind);
        });
    }

    public static function setKindNotes(notes:Array<SongNoteData>, kind:String) {
        return notes.map(function(note:SongNoteData):SongNoteData {
            return new SongNoteData(note.time, note.data, note.length, kind);
        });
    }

    public static function sortNotes(notes:Array<SongNoteData>, desc:Bool = false):Array<SongNoteData>
    {
        notes.sort(function(a:SongNoteData, b:SongNoteData):Int {
            return FlxSort.byValues(desc ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.time, b.time);
        });
        return notes;
    }

    public static function sortEvents(events:Array<SongEventData>, desc:Bool = false):Array<SongEventData>
    {
        events.sort(function(a:SongEventData, b:SongEventData):Int {
            return FlxSort.byValues(desc ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.time, b.time);
        });
        return events;
    }

    public static function sortTimeChanges(timeChanges:Array<SongTimeChange>, desc:Bool = false):Array<SongTimeChange>
    {
        timeChanges.sort(function(a:SongTimeChange, b:SongTimeChange):Int {
            return FlxSort.byValues(desc ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.timeStamp, b.timeStamp);
        });
        return timeChanges;
    }

    public static function getNotesInTimeRange(notes:Array<SongNoteData>, start:Float, end:Float):Array<SongNoteData>
    {
        return notes.filter(function(note:SongNoteData):Bool {
            return note.time >= start && note.time <= end;
        });
    }

    public static function getEventsInTimeRange(events:Array<SongEventData>, start:Float, end:Float):Array<SongEventData>
    {
        return events.filter(function(event:SongEventData):Bool {
            return event.time >= start && event.time <= end;
        });
    }

    public static function getNotesInDataRange(notes:Array<SongNoteData>, start:Int, end:Int):Array<SongNoteData>
    {
        return notes.filter(function(note:SongNoteData):Bool {
            return note.data >= start && note.data <= end;
        });
    }

    public static function getNotesWithData(notes:Array<SongNoteData>, data:Array<Int>):Array<SongNoteData>
    {
        return notes.filter(function(note:SongNoteData):Bool {
            return data.indexOf(note.data) != -1;
        });
    }

    public static function getEventsWithKind(events:Array<SongEventData>, kinds:Array<String>):Array<SongEventData>
    {
        return events.filter(function(event:SongEventData):Bool {
            return kinds.indexOf(event.eventKind) != -1;
        });
    }

    public static function writeItemsToClipboard(data:SongClipboardItems):Void
    {
        var ignoreNullOptionals = true;
        var writer = new json2object.JsonWriter<SongClipboardItems>(ignoreNullOptionals);
        var dataString:String = writer.write(data, '  ');
    
        ClipboardUtil.setClipboard(dataString);
    
        trace('Wrote ' + data.notes.length + ' notes and ' + data.events.length + ' events to clipboard.');
    }

    public static function readItemsFromClipboard():SongClipboardItems
    {
        var notesString = ClipboardUtil.getClipboard();

        trace('Read ${notesString.length} characters from clipboard.');
    
        var parser = new json2object.JsonParser<SongClipboardItems>();
        parser.ignoreUnknownVariables = false;
        parser.fromJson(notesString, 'clipboard');
        if (parser.errors.length > 0)
        {
          trace('[SongDataUtils] Error parsing note JSON data from clipboard.');
          for (error in parser.errors)
            DataError.printError(error);
          return {
            valid: false,
            notes: [],
            events: []
          };
        }
        else
        {
          var data:SongClipboardItems = parser.value;
          trace('Parsed ' + data.notes.length + ' notes and ' + data.events.length + ' from clipboard.');
          data.valid = true;
          return data;
        }
    }

    public static function buildNoteClipboard(notes:Array<SongNoteData>, ?timeOffset:Int = null):Array<SongNoteData>
    {
        if (notes.length == 0) return notes;
        if (timeOffset == null) timeOffset = Std.int(notes[0].time);
        return offsetSongNoteData(sortNotes(notes), -timeOffset);
    }
    
    public static function buildEventClipboard(events:Array<SongEventData>, ?timeOffset:Int = null):Array<SongEventData>
    {
        if (events.length == 0) return events;
        if (timeOffset == null) timeOffset = Std.int(events[0].time);
        return offsetSongEventData(sortEvents(events), -timeOffset);
    }
}

typedef SongClipboardItems =
{
  @:optional
  var valid:Bool;
  var notes:Array<SongNoteData>;
  var events:Array<SongEventData>;
}