package data.importer;

import data.importer.LeagcyData;
import data.importer.LeagcyData.LegacySongData;
import data.importer.LeagcyData.LegacySection;
import data.importer.LeagcyData.LegacyNote;

class LegacyImporter
{
    public static function parseLegacyDataRaw(input:String, fileName:String = 'raw'):LeagcyData
    {
        var parser = new json2object.JsonParser<LeagcyData>();
        parser.ignoreUnknownVariables = true; // Set to true to ignore extra variables that might be included in the JSON.
        parser.fromJson(input, fileName);
    
        if (parser.errors.length > 0)
        {
          trace('[LegacyImporter] Error parsing JSON data from ' + fileName + ':');
          for (error in parser.errors)
            DataError.printError(error);
          return null;
        }
        return parser.value;
    }

    public static function migrateMetadata(songData:LeagcyData, difficulty:String = 'normal'):SongMetadata
    {
        trace('Migrating song metadata from FNF Legacy.');

        var songMetadata:SongMetadata = new SongMetadata('Import', 'default');
    
        var hadError:Bool = false;

        songMetadata.generatedBy = 'Chart Editor Import (FNF Legacy)';

        songMetadata.playData.stage = songData?.song?.stage ?? 'stage';
        songMetadata.songName = songData?.song?.song ?? 'Import';
        songMetadata.playData.difficulties = [];
        songMetadata.playData.difficulties.push(difficulty);

        songMetadata.playData.songVariations = [];
        songMetadata.timeChanges = rebuildTimeChanges(songData);
        songMetadata.playData.characters = new SongCharacterData(songData?.song?.player1 ?? 'bf', songData?.song?.gfVersion ?? 'gf', songData?.song?.player2 ?? 'dad');
    
        return songMetadata;        
    }

    public static function migrateChartData(songData:LeagcyData, difficulty:String = 'normal'):SongChartData
    {
        trace('Migrating song chart data from FNF Legacy.');

        var songChartData:SongChartData = new SongChartData([difficulty => 1.0], [], [difficulty => []]);
    
        if (songData?.song?.notes != null) 
            songChartData.notes.set(difficulty, migrateNoteSections(songData.song.notes));
        songChartData.events = rebuildEventData(songData);
        songChartData.scrollSpeed.set(difficulty, songData.song.speed);
        return songChartData;
    }

    static function rebuildEventData(songData:LeagcyData):Array<SongEventData>
    {
        var result:Array<SongEventData> = [];

        if (songData?.song?.notes == null || songData?.song?.notes.length == 0) return result;

        var lastSectionWasMustHit:Null<Bool> = null;
        for (section in songData.song.notes)
        {
            if (section.sectionNotes.length == 0) continue;

            if (section.mustHitSection != lastSectionWasMustHit)
            {
                lastSectionWasMustHit = section.mustHitSection;
                var firstNote:LegacyNote = section.sectionNotes[0];
                result.push(new SongEventData(firstNote.time, 'FocusCamera', {char: section.mustHitSection ? 0 : 1}));
            }            
        }
        return result;
    }

    static function rebuildTimeChanges(songData:LeagcyData):Array<SongTimeChange>
    {
        var result:Array<SongTimeChange> = [];

        result.push(new SongTimeChange(0, songData?.song?.bpm ?? Constants.DEFAULT_BPM));

        if (songData?.song?.notes == null || songData?.song?.notes.length == 0) return result;

        for (section in songData?.song?.notes)
        {
            if (section.changeBPM ?? false)
            {
                var firstNote:LegacyNote = section.sectionNotes[0];
                if (firstNote != null) result.push(new SongTimeChange(firstNote.time, section.bpm));
            }
        }
        return result;
    }

    static function migrateNoteSections(input:Array<LegacySection>):Array<SongNoteData>
    {
        var result:Array<SongNoteData> = [];

        for (section in input)
        {
            var altAnim = section.altAnim ?? false;
            var mustHitSection = section.mustHitSection ?? false;
            for (note in section.sectionNotes)
            {
                var noteData = note.data;
                if (noteData < 0) continue; // Exclude Psych event notes.
                if (noteData > (4 * 2)) noteData = noteData % (2 * 4);

                if (!mustHitSection)
                {
                    if (noteData >= 4)
                        noteData -= 4;
                    else
                        noteData += 4;
                }
                var type = altAnim ? "alt" : note.type;
                result.push(new SongNoteData(note.time, noteData, note.length, type));
            }
        }
        return result;
    }
}