package data.importer;

import data.importer.LeagcyData;
import data.importer.LeagcyData.LegacyNoteSection;

class LegacyImporter
{
    public static function parseLegacyDataRaw(input:String, fileName:String = 'raw'):LeagcyData
    {
        var parser = new json2object.JsonParser<LeagcyData>();
        parser.ignoreUnknownVariables = true; // Set to true to ignore extra variables that might be included in the JSON.
        parser.fromJson(input, fileName);
      
        if (parser.errors.length > 0)
        {
            trace('[FNFLegacyImporter] Error parsing JSON data from ' + fileName + ':');
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
      
        // Set generatedBy string for debugging.
        songMetadata.generatedBy = 'Chart Editor Import (FNF Legacy)';
      
        songMetadata.playData.stage = songData?.song?.stage ?? 'mainStage';
        songMetadata.songName = songData?.song?.song ?? 'Import';
        songMetadata.playData.difficulties = [];
      
        if (songData?.song?.notes != null)
        {
            switch (songData.song.notes)
            {
              case Left(notes):
                // One difficulty of notes.
                songMetadata.playData.difficulties.push(difficulty);
              case Right(difficulties):
                if (difficulties.easy != null) songMetadata.playData.difficulties.push('easy');
                if (difficulties.normal != null) songMetadata.playData.difficulties.push('normal');
                if (difficulties.hard != null) songMetadata.playData.difficulties.push('hard');
            }
        }
      
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
        {
            switch (songData.song.notes)
            {
              case Left(notes):
                // One difficulty of notes.
                songChartData.notes.set(difficulty, migrateNoteSections(notes));
              case Right(difficulties):
                var baseDifficulty = null;
                if (difficulties.easy != null) songChartData.notes.set('easy', migrateNoteSections(difficulties.easy));
                if (difficulties.normal != null) songChartData.notes.set('normal', migrateNoteSections(difficulties.normal));
                if (difficulties.hard != null) songChartData.notes.set('hard', migrateNoteSections(difficulties.hard));
            }
        }
      
          // Import event data.
        songChartData.events = rebuildEventData(songData);
      
        switch (songData.song.speed)
        {
            case Left(speed):
              // All difficulties will use the one scroll speed.
              songChartData.scrollSpeed.set("normal", speed);
            case Right(speeds):
              if (speeds.easy != null) songChartData.scrollSpeed.set('easy', speeds.easy);
              if (speeds.normal != null) songChartData.scrollSpeed.set('normal', speeds.normal);
              if (speeds.hard != null) songChartData.scrollSpeed.set('hard', speeds.hard);
        }
      
        return songChartData;
    }

    public static function rebuildEventData(songData:LeagcyData):Array<SongEventData>
    {
        var result:Array<SongEventData> = [];
      
        var noteSections = [];
        switch (songData.song.notes)
        {
            case Left(notes):
              // All difficulties will use the one scroll speed.
              noteSections = notes;
            case Right(difficulties):
              if (difficulties.normal != null) noteSections = difficulties.normal;
              if (difficulties.hard != null) noteSections = difficulties.normal;
              if (difficulties.easy != null) noteSections = difficulties.normal;
        }
      
        if (noteSections == null || noteSections.length == 0) return result;
      
          // Add camera events.
        var lastSectionWasMustHit:Null<Bool> = null;
        for (section in noteSections)
        {
            // Skip empty sections.
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

    public static function rebuildTimeChanges(songData:LeagcyData):Array<SongTimeChange>
    {
        var result:Array<SongTimeChange> = [];
      
        result.push(new SongTimeChange(0, songData?.song?.bpm ?? Constants.DEFAULT_BPM));
      
        var noteSections = [];
        switch (songData.song.notes)
        {
            case Left(notes):
              // All difficulties will use the one scroll speed.
              noteSections = notes;
            case Right(difficulties):
              if (difficulties.normal != null) noteSections = difficulties.normal;
              if (difficulties.hard != null) noteSections = difficulties.normal;
              if (difficulties.easy != null) noteSections = difficulties.normal;
        }
      
        if (noteSections == null || noteSections.length == 0) return result;
      
        for (noteSection in noteSections)
        {
            if (noteSection.changeBPM ?? false)
            {
              var firstNote:LegacyNote = noteSection.sectionNotes[0];
              if (firstNote != null) result.push(new SongTimeChange(firstNote.time, noteSection.bpm));
            }
        }
      
        return result;
    }
      
    static final STRUMLINE_SIZE = 4;
      
    public static function migrateNoteSections(input:Array<LegacyNoteSection>):Array<SongNoteData>
    {
        var result:Array<SongNoteData> = [];
      
        for (section in input)
        {
            var mustHitSection = section.mustHitSection ?? false;
            for (note in section.sectionNotes)
            {
              // Handle the dumb logic for mustHitSection.
              var noteData = note.data;
              if (noteData < 0) continue; // Exclude Psych event notes.
              if (noteData > (STRUMLINE_SIZE * 2)) noteData = noteData % (2 * STRUMLINE_SIZE); // Handle other engine event notes.
      
              // Flip notes if mustHitSection is FALSE (not true lol).
              if (!mustHitSection)
              {
                if (noteData >= STRUMLINE_SIZE)
                    noteData -= STRUMLINE_SIZE;
                else
                    noteData += STRUMLINE_SIZE;
              }
      
              result.push(new SongNoteData(note.time, noteData, note.length, note.type));
            }
        }
      
        return result;
    }
}