package meta.data;

class PlayableCharacter implements IRegistryEntry<PlayerData>
{
    public final id:String;
    public final _data:Null<PlayerData>;

    public function new(id:String)
    {
        this.id = id;
        _data = _fetchData(id);
    
        if (_data == null)
            throw 'Could not parse playable character data for id: $id';
    }

    public function getName():String return _data?.name ?? "Unknown";
    public function getOwnedCharacterIds():Array<String> return _data?.ownedChars ?? [];
    public function shouldShowUnownedChars():Bool return _data?.showUnownedChars ?? false;
    public function shouldShowCharacter(id:String):Bool 
    {
        if (getOwnedCharacterIds().contains(id)) return true;

        if (shouldShowUnownedChars())
        {
            var result = !PlayerRegistry.instance.isCharacterOwned(id);
            return result;
        }
        return false;
    }

    public function getFreeplayStyleID():String return _data?.freeplayStyle ?? 'bf';
    public function getFreeplayDJData():Null<PlayerFreeplayDJData> return _data?.freeplayDJ;
    public function getFreeplayDJText(index:Int):String return _data?.freeplayDJ?.getFreeplayDJText(index) ?? 'GET FREAKY ON A FRIDAY';
    public function getCharSelectData():Null<PlayerCharSelectData> return _data?.charSelect;
    public function isUnlocked():Bool return _data?.unlocked ?? true;
    public function destroy():Void {}
    public function toString():String return 'PlayableCharacter($id)';
    static function _fetchData(id:String):Null<PlayerData> return PlayerRegistry.instance.parseEntryDataWithMigration(id, PlayerRegistry.instance.fetchEntryVersion(id));

}