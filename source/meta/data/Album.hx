package meta.data;

class Album implements IRegistryEntry<AlbumData>
{
    public final id:String;
    public final _data:AlbumData;
  
    public function new(id:String)
    {
        this.id = id;
        this._data = _fetchData(id);
    
        if (_data == null)
        {
          throw 'Could not parse album data for id: $id';
        }
    }

    public function getAlbumName():String return _data.name;
    public function getAlbumArtists():Array<String> return _data.artists;
    public function getAlbumArtAssetKey():String return _data.albumArtAsset;
    public function getAlbumArtGraphic():FlxGraphic return FlxG.bitmap.add(Paths.image(getAlbumArtAssetKey()));
    public function getAlbumTitleAssetKey():String return _data.albumTitleAsset;
    public function hasAlbumTitleAnimations()  return _data.albumTitleAnimations.length > 0;
    public function getAlbumTitleAnimations():Array<AnimationData> return _data.albumTitleAnimations;
    public function toString():String return 'Album($id)';
    public function destroy():Void {}

    static function _fetchData(id:String):Null<AlbumData> return AlbumRegistry.instance.parseEntryDataWithMigration(id, AlbumRegistry.instance.fetchEntryVersion(id));
}