package data;

import meta.util.tools.ICloneable;
import thx.semver.Version;

class SongMetadata implements ICloneable<SongMetadata>
{
    @:jcustomparse(data.DataParse.semverVersion)
    @:jcustomwrite(data.DataWrite.semverVersion)
    public var version:Version;

    @:default("Unknown")
    public var songName:String;
  
    @:default("Unknown")
    public var artist:String;
  
    @:optional
    public var charter:Null<String> = null;
  
    @:optional
    @:default(96)
    public var divisions:Null<Int>; // Optional field
  
    @:optional
    @:default(false)
    public var looped:Bool;

    @:optional
    public var offsets:Null<SongOffsets>;

    public var playData:SongPlayData;

    @:default(data.registry.SongRegistry.DEFAULT_GENERATEDBY)
    public var generatedBy:String;
  
    @:optional
    @:default('ms')
    public var timeFormat:SongTimeFormat;
    public var timeChanges:Array<SongTimeChange>;

    @:jignored
    public var variation:String;

    public function new(songName:String, ?variation:String)
    {
        this.version = SongRegistry.SONG_METADATA_VERSION;
        this.songName = songName;
        this.artist = "Unknown";
        this.timeFormat = 'ms';
        this.divisions = null;
        this.offsets = new SongOffsets();
        this.timeChanges = [new SongTimeChange(0, 100)];
        this.looped = false;
        this.playData = new SongPlayData();
        this.playData.songVariations = [];
        this.playData.difficulties = [];
        this.playData.characters = new SongCharacterData('bf', 'gf', 'dad');
        this.playData.stage = 'mainStage';
        this.playData.noteStyle = Constants.DEFAULT_NOTE_STYLE;
        this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
        // Variation ID.
        this.variation = (variation == null) ? Constants.DEFAULT_VARIATION : variation;
    }

    public function clone():SongMetadata
    {
        var result:SongMetadata = new SongMetadata(this.songName, this.variation);
        result.version = this.version;
        result.timeFormat = this.timeFormat;
        result.divisions = this.divisions;
        result.offsets = this.offsets != null ? this.offsets.clone() : new SongOffsets(); // if no song offsets found (aka null), so just create new ones
        result.timeChanges = this.timeChanges.deepClone();
        result.looped = this.looped;
        result.playData = this.playData.clone();
        result.generatedBy = this.generatedBy;
    
        return result;
    }
    
    public function serialize():String
    {
        updateVersionToLatest();

        var writer = new json2object.JsonWriter<SongMetadata>(true);
        return writer.write(this, '\t');
    }

    public function updateVersionToLatest():Void
    {
        this.version = SongRegistry.SONG_METADATA_VERSION;
        this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
    }

    public function toString():String  return 'SongMetadata(${this.songName} by ${this.artist}, variation ${this.variation})';
}

class SongMusicData implements ICloneable<SongMusicData>
{
  /**
   * A semantic versioning string for the song data format.
   *
   */
  // @:default(funkin.data.song.SongRegistry.SONG_METADATA_VERSION)
  @:jcustomparse(data.DataParse.semverVersion)
  @:jcustomwrite(data.DataWrite.semverVersion)
  public var version:Version;

  @:default("Unknown")
  public var songName:String;

  @:default("Unknown")
  public var artist:String;

  @:optional
  @:default(96)
  public var divisions:Null<Int>; // Optional field

  @:optional
  @:default(false)
  public var looped:Null<Bool>;

  // @:default(funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY)
  public var generatedBy:String;

  // @:default(funkin.data.song.SongData.SongTimeFormat.MILLISECONDS)
  public var timeFormat:SongTimeFormat;

  // @:default(funkin.data.song.SongData.SongTimeChange.DEFAULT_SONGTIMECHANGES)
  public var timeChanges:Array<SongTimeChange>;

  /**
   * Defaults to `Constants.DEFAULT_VARIATION`. Populated later.
   */
  @:jignored
  public var variation:String;

  public function new(songName:String, artist:String, variation:String = 'default')
  {
    this.version = SongRegistry.SONG_CHART_DATA_VERSION;
    this.songName = songName;
    this.artist = artist;
    this.timeFormat = 'ms';
    this.divisions = null;
    this.timeChanges = [new SongTimeChange(0, 100)];
    this.looped = false;
    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
    // Variation ID.
    this.variation = variation == null ? Constants.DEFAULT_VARIATION : variation;
  }

  public function updateVersionToLatest():Void
  {
    this.version = SongRegistry.SONG_MUSIC_DATA_VERSION;
    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
  }

  public function clone():SongMusicData
  {
    var result:SongMusicData = new SongMusicData(this.songName, this.artist, this.variation);
    result.version = this.version;
    result.timeFormat = this.timeFormat;
    result.divisions = this.divisions;
    result.timeChanges = this.timeChanges.clone();
    result.looped = this.looped;
    result.generatedBy = this.generatedBy;

    return result;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongMusicData(${this.songName} by ${this.artist}, variation ${this.variation})';
  }
}


enum abstract SongTimeFormat(String) from String to String
{
  var TICKS = 'ticks';
  var FLOAT = 'float';
  var MILLISECONDS = 'ms';
}

class SongTimeChange implements ICloneable<SongTimeChange>
{
    public static final DEFAULT_SONGTIMECHANGE:SongTimeChange = new SongTimeChange(0, 100);

    public static final DEFAULT_SONGTIMECHANGES:Array<SongTimeChange> = [DEFAULT_SONGTIMECHANGE];
  
    static final DEFAULT_BEAT_TUPLETS:Array<Int> = [4, 4, 4, 4];
    static final DEFAULT_BEAT_TIME:Null<Float> = null;

    @:alias("t")
    public var timeStamp:Float;

    @:optional
    @:alias("b")
    public var beatTime:Float;  

    public var bpm:Float;

    @:default(4)
    @:optional
    @:alias("n")
    public var timeSignatureNum:Int;

    @:default(4)
    @:optional
    @:alias("d")
    public var timeSignatureDen:Int;

    @:optional
    @:alias("bt")
    public var beatTuplets:Array<Int>;

    public function new(timeStamp:Float, bpm:Float, timeSignatureNum:Int = 4, timeSignatureDen:Int = 4, ?beatTime:Float, ?beatTuplets:Array<Int>)
    {
        this.timeStamp = timeStamp;
        this.bpm = bpm;
    
        this.timeSignatureNum = timeSignatureNum;
        this.timeSignatureDen = timeSignatureDen;
    
        this.beatTime = beatTime == null ? DEFAULT_BEAT_TIME : beatTime;
        this.beatTuplets = beatTuplets == null ? DEFAULT_BEAT_TUPLETS : beatTuplets;
    }

    public function clone():SongTimeChange 
    {
        return new SongTimeChange(this.timeStamp, this.bpm, this.timeSignatureNum, this.timeSignatureDen, this.beatTime, this.beatTuplets);
    }

    public function toString():String  return 'SongTimeChange(${this.timeStamp}ms,${this.bpm}bpm)';
}

class SongOffsets implements ICloneable<SongOffsets>
{
    @:optional
    @:default(0)
    public var instrumental:Float;

    @:optional
    @:default([])
    public var altInstrumentals:Map<String, Float>;

    @:optional
    @:default([])
    public var vocals:Map<String, Float>;

    @:optional
    @:default([])
    public var altVocals:Map<String, Map<String, Float>>;
  
    public function new(instrumental:Float = 0.0, ?altInstrumentals:Map<String, Float>, ?vocals:Map<String, Float>, ?altVocals:Map<String, Map<String, Float>>)
    {
        this.instrumental = instrumental;
        this.altInstrumentals = altInstrumentals == null ? new Map<String, Float>() : altInstrumentals;
        this.vocals = vocals == null ? new Map<String, Float>() : vocals;
        this.altVocals = altVocals == null ? new Map<String, Map<String, Float>>() : altVocals;
    }

    public function getInstrumentalOffset(?instrumental:String):Float 
    {
        if (instrumental == null || instrumental == '') return this.instrumental;

        if (!this.altInstrumentals.exists(instrumental)) return this.instrumental;
    
        return this.altInstrumentals.get(instrumental);
    }

    public function setInstrumentalOffset(value:Float, ?instrumental:String):Float
    {
        if (instrumental == null || instrumental == '')
            this.instrumental = value;
        else
            this.altInstrumentals.set(instrumental, value);
        return value;
    }

    public function getVocalOffset(charId:String, ?instrumental:String):Float
    {
        if (instrumental == null)
        {
            if (!this.vocals.exists(charId)) return 0.0;
            return this.vocals.get(charId);
        }
        else
        {
            if (!this.altVocals.exists(instrumental)) return 0.0;
            if (!this.altVocals.get(instrumental).exists(charId)) return 0.0;
            return this.altVocals.get(instrumental).get(charId);
        }
    }

    public function setVocalOffset(charId:String, value:Float):Float
    {
        this.vocals.set(charId, value);
        return value;
    }

    public function clone():SongOffsets
    {
        var result:SongOffsets = new SongOffsets(this.instrumental);
        result.altInstrumentals = this.altInstrumentals.clone();
        result.vocals = this.vocals.clone();
    
        return result;
    }

    public function toString():String   return 'SongOffsets(${this.instrumental}ms, ${this.altInstrumentals}, ${this.vocals}, ${this.altVocals})';
}

class SongPlayData implements ICloneable<SongPlayData>
{
    @:default([])
    @:optional
    public var songVariations:Array<String>;
    @:default(['normal'])
    @:optional
    public var difficulties:Array<String>;

    public var characters:SongCharacterData;

    @:default('stage')
    @:optional
    public var stage:String;

    @:default('base')
    @:optional
    public var noteStyle:String;

    @:optional
    @:default(['normal' => 0])
    public var ratings:Map<String, Int>;

    @:optional
    public var album:Null<String>;

    @:optional
    @:default(0.0)
    public var previewStart:Float;
    
    @:optional
    @:default(0.5)
    public var previewEnd:Float;
  
    public function new()
    {
        ratings = new Map<String, Int>();
    }

    public function clone():SongPlayData
    {
        var result:SongPlayData = new SongPlayData();
        result.songVariations = this.songVariations.clone();
        result.difficulties = this.difficulties.clone();
        result.characters = this.characters.clone();
        result.stage = this.stage;
        result.noteStyle = this.noteStyle;
        result.ratings = this.ratings.clone();
        result.album = this.album;
        result.previewStart = this.previewStart;
        result.previewEnd = this.previewEnd;
    
        return result;
    }

    public function toString():String return 'SongPlayData(${this.songVariations}, ${this.difficulties})';
}

class SongCharacterData implements ICloneable<SongCharacterData>
{
    @:optional
    @:default('')
    public var player:String = '';
  
    @:optional
    @:default('')
    public var girlfriend:String = '';
  
    @:optional
    @:default('')
    public var opponent:String = '';

    @:optional
    @:default([])
    public var others:Array<String> = [];
  
    @:optional
    @:default('')
    public var instrumental:String = '';
  
    @:optional
    @:default([])
    public var altInstrumentals:Array<String> = [];
  
    @:optional
    public var opponentVocals:Null<Array<String>> = null;
  
    @:optional
    public var playerVocals:Null<Array<String>> = null;

    public function new(player:String = '', girlfriend:String = '', opponent:String = '', ?others:Array<String>, instrumental:String = '', ?altInstrumentals:Array<String>,
        ?opponentVocals:Array<String>, ?playerVocals:Array<String>)
    {
        this.player = player;
        this.girlfriend = girlfriend;
        this.opponent = opponent;
        this.others = others;

        this.instrumental = instrumental;
        this.altInstrumentals = altInstrumentals;
        this.opponentVocals = opponentVocals;
        this.playerVocals = playerVocals;
        
    
        if (opponentVocals == null) this.opponentVocals = [opponent];
        if (playerVocals == null) this.playerVocals = [player];
    }

    public function clone():SongCharacterData
    {
        var result:SongCharacterData = new SongCharacterData(this.player, this.girlfriend, this.opponent, this.others, this.instrumental);
        result.altInstrumentals = this.altInstrumentals.clone();
    
        return result;
    }

    public function toString():String  return 'SongCharacterData(${this.player}, ${this.girlfriend}, ${this.opponent}, ${this.others}, ${this.instrumental}, [${this.altInstrumentals.join(', ')}])';
}

class SongChartData implements ICloneable<SongChartData>
{
    @:default(data.registry.SongRegistry.SONG_CHART_DATA_VERSION)
    @:jcustomparse(data.DataParse.semverVersion)
    @:jcustomwrite(data.DataWrite.semverVersion)
    public var version:Version;

    public var events:Array<SongEventData>;
    public var scrollSpeed:Map<String, Float>;
    public var notes:Map<String, Array<SongNoteData>>;

    @:default(data.registry.SongRegistry.DEFAULT_GENERATEDBY)
    public var generatedBy:String;

    @:jignored
    public var variation:String;

    public function new(scrollSpeed:Map<String, Float>, events:Array<SongEventData>, notes:Map<String, Array<SongNoteData>>)
    {
        this.version = SongRegistry.SONG_CHART_DATA_VERSION;

        this.events = events;
        this.notes = notes;

        this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
    }

    public function getScrollSpeed(diff:String = 'default'):Float
    {
        var result:Float = this.scrollSpeed.get(diff);
        if (result == 0.0 && diff != 'default') return getScrollSpeed('default');
        return (result == 0.0) ? 1.0 : result;
    } 

    public function setScrollSpeed(value:Float, diff:String = 'default'):Float
    {
        this.scrollSpeed.set(diff, value);
        return value;
    }

    public function getNotes(diff:String):Array<SongNoteData>
    {
        var result:Array<SongNoteData> = this.notes.get(diff);
        if (result == null && diff != 'normal') return getNotes('normal');
        return (result == null) ? [] : result;
    }

    public function setNotes(value:Array<SongNoteData>, diff:String):Array<SongNoteData>
    {
        this.notes.set(diff, value);
        return value;
    }

    //**Make Cleaner Chart**/
    public function serialize():String
    {
        var chartData = {
            version: "2.0.0",
            events: [],
            scrollSpeed: ['yourmom' => 9.9],
            notes: ['yourmom' => []],
            generatedBy: SongRegistry.DEFAULT_GENERATEDBY
        };

        for(eventData in this.events)
        {
            chartData.events.push({
                t: eventData.time,
                e: eventData.eventKind,
                v: eventData.value
            });
        }

        for (keyNote in this.notes.keys())
        {
            var myNotes:Array<Dynamic> = [];
            for(note in getNotes(keyNote))
            {
                var funiNote:Dynamic = {t: note.time, d: note.data};

                if(note.length > 0) 
                    funiNote.l = note.length;
                if(note.kind != null && note.kind.length > 0)
                    funiNote.k = note.kind;
                if(note.params != null && note.params.length > 0)
                    funiNote.p = note.params;

                myNotes.push(funiNote);
            }
            chartData.notes.set(keyNote, myNotes);
        }

        for (keyScrollSpeed in this.scrollSpeed.keys())
            chartData.scrollSpeed.set(keyScrollSpeed, this.getScrollSpeed(keyScrollSpeed));

        //this is Placeholder reminder to make Map work
        chartData.scrollSpeed.remove('yourmom');
        chartData.notes.remove('yourmom');

        var data:String = FunkyJson.stringify(chartData, "\t");

        return data.trim();
    }

    public function updateVersionToLatest():Void
    {
        this.version = SongRegistry.SONG_CHART_DATA_VERSION;
        this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
    }

    public function clone():SongChartData
    {
        var strumlineClone:Map<String, Array<SongNoteData>> = new Map<String, Array<SongNoteData>>();
        for (key in this.notes.keys()) strumlineClone.set(key, this.getNotes(key).deepClone());
        var eventDataClone:Array<SongEventData> = this.events.deepClone();

        var result:SongChartData = new SongChartData(this.scrollSpeed.clone(), eventDataClone, strumlineClone);
        result.version = this.version;
        result.generatedBy = this.generatedBy;
        result.variation = this.variation;
    
        return result;
    }

    public function toString():String   return 'SongChartData(${this.events.length} events, ${this.notes.size()} difficulties, ${generatedBy})';
}

class SongEventData implements ICloneable<SongEventData>
{
    @:alias("t")
    public var time(default, set):Float;
  
    function set_time(value:Float):Float
    {
        _stepTime = null;
        return time = value;
    }

    @:alias("e")
    public var eventKind:String;

    @:alias("v")
    @:optional
    @:jcustomparse(data.DataParse.dynamicValue)
    @:jcustomwrite(data.DataWrite.dynamicValue)
    public var value:Dynamic = null;

    @:jignored
    public var activated:Bool = false;
  
    public function new(time:Float, eventKind:String, value:Dynamic = null)
    {
        this.time = time;
        this.eventKind = eventKind;
        this.value = value;
    }

    @:jignored
    var _stepTime:Null<Float> = null;
  
    public function getStepTime(force:Bool = false):Float
    {
        if (_stepTime != null && !force) return _stepTime;

        return _stepTime = Conductor.instance.getTimeInSteps(this.time);
    }

    public function clone():SongEventData 
    {
        return new SongEventData(this.time, this.eventKind, this.value);
    }

    public function valueAsStruct(?defaultKey:String = "key"):Dynamic
    {
        if (this.value == null) return {};
        if (Std.isOfType(this.value, Array))
        {
          var result:haxe.DynamicAccess<Dynamic> = {};
          result.set(defaultKey, this.value);
          return cast result;
        }
        else if (Reflect.isObject(this.value))
        {
          // We enter this case if the value is a struct.
          return cast this.value;
        }
        else
        {
          var result:haxe.DynamicAccess<Dynamic> = {};
          result.set(defaultKey, this.value);
          return cast result;
        }
    }

   

    public function getHandler():Null<SongEvent> return SongEventRegistry.getEvent(this.eventKind);
    public function getSchema():Null<SongEventSchema> return SongEventRegistry.getEventSchema(this.eventKind);

    public function getDynamic(key:String):Null<Dynamic> return this.value == null ? null : Reflect.field(this.value, key);
    public function getBool(key:String):Null<Bool> return this.value == null ? null : cast Reflect.field(this.value, key);
    public function getString(key:String):String return this.value == null ? null : cast Reflect.field(this.value, key);
    public function getArray(key:String):Array<Dynamic>   return this.value == null ? null : cast Reflect.field(this.value, key);
    public function getBoolArray(key:String):Array<Bool>   return this.value == null ? null : cast Reflect.field(this.value, key);
    public function getInt(key:String):Null<Int>
    {
        if (this.value == null) return null;
        var result = Reflect.field(this.value, key);
        if (result == null) return null;
        if (Std.isOfType(result, Int)) return result;
        if (Std.isOfType(result, String)) return Std.parseInt(cast result);
        return cast result;
    }

    public function getFloat(key:String):Null<Float>
    {
        if (this.value == null) return null;
        var result = Reflect.field(this.value, key);
        if (result == null) return null;
        if (Std.isOfType(result, Float)) return result;
        if (Std.isOfType(result, String)) return Std.parseFloat(cast result);
        return cast result;
    }

    public function buildTooltip():String
    {
        var eventHandler = getHandler();
        var eventSchema = getSchema();
    
        if (eventSchema == null) return 'Unknown Event: ${this.eventKind}';
    
        var result = '${eventHandler.getTitle()}';
    
        var defaultKey = eventSchema.getFirstField()?.name;
        var valueStruct:haxe.DynamicAccess<Dynamic> = valueAsStruct(defaultKey);
    
        for (pair in valueStruct.keyValueIterator())
        {
          var key = pair.key;
          var value = pair.value;
    
          var title = eventSchema.getByName(key)?.title ?? 'UnknownField';
    
          // if (eventSchema.stringifyFieldValue(key, value) != null) trace(eventSchema.stringifyFieldValue(key, value));
          var valueStr = eventSchema.stringifyFieldValue(key, value) ?? 'UnknownValue';
    
          result += '\n- ${title}: ${valueStr}';
        }
    
        return result;
    }

    public function toString():String  return 'SongEventData(${this.time}ms, ${this.eventKind}: ${this.value})';
}

class SongNoteData implements ICloneable<SongNoteData>
{
    @:alias("t")
    public var time(default, set):Float;
  
    function set_time(value:Float):Float
    {
        _stepTime = null;
        return time = value;
    }

    @:alias("d")
    public var data:Int;

    @:alias("l")
    @:default(0)
    @:optional
    public var length(default, set):Float;
  
    function set_length(value:Float):Float
    {
        _stepLength = null;
        return length = value;
    }

    @:alias("k")
    @:optional
    @:isVar
    public var kind(get, set):Null<String> = null;
  
    function get_kind():Null<String>
    {
        if (this.kind == null || this.kind == '') return null;
        return this.kind;
    }

    function set_kind(value:Null<String>):Null<String>
    {
        if (value == '') value = null;
        return this.kind = value;
    }

    @:alias("p")
    @:default([])
    @:optional
    public var params:Array<NoteParamData>;

    public function new(time:Float, data:Int, length:Float = 0, kind:String = '', ?params:Array<NoteParamData>)
    {
        this.time = time;
        this.data = data;
        this.length = length;
        this.kind = kind;
        this.params = params ?? [];
    }

    public inline function getDirection(strumlineSize:Int = 4):Int   return this.data % strumlineSize;
    public function getStrumlineIndex(strumlineSize:Int = 4):Int  return Math.floor(this.data / strumlineSize);

    public function getDirectionName(strumlineSize:Int = 4):String
    {
        switch (data % strumlineSize)
        {
          case 0:
            return 'Left';
          case 1:
            return 'Down';
          case 2:
            return 'Up';
          case 3:
            return 'Right';
          default:
            return 'Unknown';
        }        
    }

    public static function buildDirectionName(data:Int, strumlineSize:Int = 4):String
    {
        switch (data % strumlineSize)
        {
          case 0:
            return 'Left';
          case 1:
            return 'Down';
          case 2:
            return 'Up';
          case 3:
            return 'Right';
          default:
            return 'Unknown';
        }
    }

    public function buildTooltip():String
    {
        if (kind == null) return 'Unknown Note Kind: ${this.kind}';
        var result = '${meta.state.editors.charting.util.ChartEditorDropdowns.NOTE_KINDS.get(this.kind)}';
        return result;
    }

    @:jignored
    var _stepTime:Null<Float> = null;

    public function getStepTime(force:Bool = false):Float
    {
        if (_stepTime != null && !force) return _stepTime;

        return _stepTime = Conductor.instance.getTimeInSteps(this.time);
    }

    @:jignored
    var _stepLength:Null<Float> = null;

    public function getStepLength(force = false):Float
    {
        if (this.length <= 0) return 0.0;
        if (_stepLength != null && !force) return _stepLength;
        return _stepLength = Conductor.instance.getTimeInSteps(this.time + this.length) - getStepTime();
    }

    public function setStepLength(value:Float):Void
    {
        if (value <= 0)
            this.length = 0.0;
        else
        {
            var endStep:Float = getStepTime() + value;
            var endMs:Float = Conductor.instance.getStepTimeInMs(endStep);
            var lengthMs:Float = endMs - this.time;
        
            this.length = lengthMs;
        }
        
        // Recalculate the step length next time it's requested.
        _stepLength = null;
    }

    public function cloneParams():Array<NoteParamData>
    {
        var params:Array<NoteParamData> = [];
        for (param in this.params) params.push(param.clone());
        return params;
    }

    public function clone():SongNoteData
    {
        return new SongNoteData(this.time, this.data, this.length, this.kind, cloneParams());
    }

    public function toString():String 
    {
        return 'SongNoteData(${this.time}ms, ' + (this.length > 0 ? '[${this.length}ms hold]' : '') + ' ${this.data}'
        + (this.kind != '' ? ' [kind: ${this.kind}])' : ')');
    }
}

class NoteParamData implements ICloneable<NoteParamData>
{
    @:alias("n")
    public var name:String;
  
    @:alias("v")
    @:jcustomparse(data.DataParse.dynamicValue)
    @:jcustomwrite(data.DataWrite.dynamicValue)
    public var value:Dynamic;
  
    public function new(name:String, value:Dynamic)
    {
      this.name = name;
      this.value = value;
    }

    public function clone():NoteParamData
    {
        return new NoteParamData(this.name, this.value);
    }

    public function toString():String return 'NoteParamData(${this.name}, ${this.value})';
}