package data.registry;
import meta.data.ScriptedPlayableCharacter;

class PlayerRegistry extends BaseRegistry<PlayableCharacter, PlayerData>
{
    public static final PLAYER_DATA_VERSION:thx.semver.Version = "1.0.0";

    public static final PLAYER_DATA_VERSION_RULE:thx.semver.VersionRule = "1.0.x";
  
    public static var instance(get, never):PlayerRegistry;
    static var _instance:Null<PlayerRegistry> = null;

    static function get_instance():PlayerRegistry
    {
        if (_instance == null) _instance = new PlayerRegistry();
        return _instance;
    }

    var ownedCharacterIds:Map<String, String> = [];

    public function new()
    {
        super('PLAYER', 'players', PLAYER_DATA_VERSION_RULE);
    }

    public override function loadEntries():Void
    {
        super.loadEntries();

        for (playerId in listEntryIds())
        {
          var player = fetchEntry(playerId);
          if (player == null) continue;
    
          var currentPlayerCharIds = player.getOwnedCharacterIds();
          for (characterId in currentPlayerCharIds)
          {
            ownedCharacterIds.set(characterId, playerId);
          }
        }
    
        log('Loaded ${countEntries()} playable characters with ${ownedCharacterIds.size()} associations.');
    }

    public function countUnlockedCharacters():Int
    {
        var count = 0;

        for (charId in listEntryIds())
        {
          var player = fetchEntry(charId);
          if (player == null) continue;
    
          if (player.isUnlocked()) count++;
        }
    
        return count;
    }

    public function hasNewCharacter():Bool
    {
        var charactersSeen = Init.trueSettings.get('Playable Character');
        for (charId in listEntryIds())
        {
            var player = fetchEntry(charId);
            if (player == null) continue;
        
            if (!player.isUnlocked()) continue;
            if (charactersSeen.contains(charId)) continue;
        
              // This character is unlocked but we haven't seen them in Freeplay yet.
            return true;
        }
        
        // Fallthrough case.
        return false;
    }

    public function listNewCharacters():Array<String>
    {
        var charactersSeen = Init.trueSettings.get('Playable Character');
        var result = [];
    
        for (charId in listEntryIds())
        {
          var player = fetchEntry(charId);
          if (player == null) continue;
    
          if (!player.isUnlocked()) continue;
          if (charactersSeen.contains(charId)) continue;
    
          // This character is unlocked but we haven't seen them in Freeplay yet.
          result.push(charId);
        }
    
        return result;
    }

    public function getCharacterOwnerId(characterId:Null<String>):Null<String>
    {
        if (characterId == null) return null;
        return ownedCharacterIds[characterId];
    }

    public function isCharacterOwned(characterId:String):Bool return ownedCharacterIds.exists(characterId);

    public function parseEntryData(id:String):Null<PlayerData>
    {
        var parser = new json2object.JsonParser<PlayerData>();
        parser.ignoreUnknownVariables = false;
    
        switch (loadEntryFile(id))
        {
          case {fileName: fileName, contents: contents}:
            parser.fromJson(contents, fileName);
          default:
            return null;
        }
    
        if (parser.errors.length > 0)
        {
          printErrors(parser.errors, id);
          return null;
        }
        return parser.value;
    }

    public function parseEntryDataRaw(contents:String, ?fileName:String):Null<PlayerData>
    {
        var parser = new json2object.JsonParser<PlayerData>();
        parser.ignoreUnknownVariables = false;
        parser.fromJson(contents, fileName);
    
        if (parser.errors.length > 0)
        {
          printErrors(parser.errors, fileName);
          return null;
        }
        return parser.value;
    }

    function createScriptedEntry(clsName:String):PlayableCharacter return ScriptedPlayableCharacter.init(clsName, "unknown");
    function getScriptedClassNames():Array<String> return ScriptedPlayableCharacter.listScriptClasses();
    public function listBaseGamePlayerIds():Array<String> return ["bf", "pico"];

    public function listModdedPlayerIds():Array<String>
    {
        return listEntryIds().filter(function(id:String):Bool {
            return listBaseGamePlayerIds().indexOf(id) == -1;
        });
    }
}