package meta.data;

class SongSerializer
{
    public static function importSongChartDataSync(path:String):SongChartData
    {
        var fileData = FileUtil.readStringFromPath(path);

        if (fileData == null) return null;
    
        var songChartData:SongChartData = fileData.parseJSON();
    
        return songChartData;
    }

    public static function importSongMetadataSync(path:String):SongMetadata
    {
        var fileData = FileUtil.readStringFromPath(path);

        if (fileData == null) return null;
    
        var songMetadata:SongMetadata = fileData.parseJSON();
    
        return songMetadata;
    }

    public static function importSongChartDataAsync(callback:SongChartData->Void):Void
    {
        FileUtil.browseFileReference(function(fileReference:FileReference) {
            var data = fileReference.data.toString();
      
            if (data == null) return;
      
            var songChartData:SongChartData = data.parseJSON();
      
            if (songChartData != null) callback(songChartData);
        });
    }

    public static function importSongMetadataAsync(callback:SongMetadata->Void):Void
    {
        FileUtil.browseFileReference(function(fileReference:FileReference) {
            var data = fileReference.data.toString();
      
            if (data == null) return;
      
            var songMetadata:SongMetadata = data.parseJSON();
      
            if (songMetadata != null) callback(songMetadata);
        });
    }
}