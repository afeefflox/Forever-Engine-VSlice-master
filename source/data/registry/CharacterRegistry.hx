package data.registry;

import gameObjects.character.ScriptedCharacter.ScriptedBaseCharacter;
import gameObjects.character.ScriptedCharacter.ScriptedAtlasCharacter;
import gameObjects.character.ScriptedCharacter.ScriptedMultiAtlasCharacter;
import gameObjects.character.ScriptedCharacter.ScriptedAnimateAtlasCharacter;
import openfl.utils.Assets;


class CharacterRegistry {
    public static final CHARACTER_DATA_VERSION:String = '1.0.1';

    public static final CHARACTER_DATA_VERSION_RULE:String = '1.0.x';

    public static final characterCache:Map<String, CharacterData> = new Map<String, CharacterData>();
    static final characterScriptedClass:Map<String, String> = new Map<String, String>();
  
    static final DEFAULT_CHAR_ID:String = 'UNKNOWN';

    public static var DEFAULT_CHARACTER:CharacterData = {
      animations: [
        {
          name: "idle",
          prefix: "BF idle dance",
          assetPath: "",
          offsets: [0, 0],
          looped: false,
          frameRate: 24,
          frameIndices: []
        }
      ],
      version: CHARACTER_DATA_VERSION,
      name: "Placeholder Boyfriend",
      assetPath: "characters/BOYFRIEND",
      renderType: CharacterRenderType.Atlas,
      offsets: [0, 0],
      cameraOffsets: [0, 0],
      antialiasing: true,
      scale: 1,
      flipX: false,
      isPlayer: false,
      healthIcon: {
        id: "face",
        scale: 1,
        flipX: false,
        antialiasing: true,
        offsets: [0, 0]
      },
      death: {
        cameraOffsets: [0, 0],
        cameraZoom: 1,
        preTransitionDelay: 0
      }
    }
    
    public static function loadCharacterCache():Void
    {
        clearCharacterCache();
        trace('[CHARACTER] Parsing all entries...');

        var charIdList:Array<String> = DataAssets.listDataFilesInPath('characters/');
        var unscriptedCharIds:Array<String> = charIdList.filter(function(charId:String):Bool {
          return !characterCache.exists(charId);
        });
        trace('  Fetching data for ${unscriptedCharIds.length} characters...');
        for (charId in unscriptedCharIds)
        {
          try
          {
            var charData:CharacterData = parseCharacterData(charId);
            if (charData != null)
            {
              trace('    Loaded character data: ${charId}');
              characterCache.set(charId, charData);
            }
          }
          catch (e)
          {
            // Assume error was already logged.
            continue;
          }
        }

        var scriptedCharClassNames1:Array<String> = ScriptedAtlasCharacter.listScriptClasses();
        if (scriptedCharClassNames1.length > 0)
        {
          trace('  Instantiating ${scriptedCharClassNames1.length} (Atlas) scripted characters...');
          for (charCls in scriptedCharClassNames1)
          {
            try
            {
              var character:AtlasCharacter = ScriptedAtlasCharacter.init(charCls, DEFAULT_CHAR_ID);
              trace('  Initialized character ${character.characterName}');
              characterScriptedClass.set(character.id, charCls);
            }
            catch (e)
            {
              trace('    FAILED to instantiate scripted Atlas character: ${charCls}');
              trace(e);
            }
          }
        }

        var scriptedCharClassNames2:Array<String> = ScriptedMultiAtlasCharacter.listScriptClasses();
        if (scriptedCharClassNames2.length > 0)
        {
          trace('  Instantiating ${scriptedCharClassNames2.length} (MutilAtlas) scripted characters...');
          for (charCls in scriptedCharClassNames2)
          {
            try
            {
              var character:MultiAtlasCharacter = ScriptedMultiAtlasCharacter.init(charCls, DEFAULT_CHAR_ID);
              trace('  Initialized character ${character.characterName}');
              characterScriptedClass.set(character.id, charCls);
            }
            catch (e)
            {
              trace('    FAILED to instantiate scripted Mutil Atlas character: ${charCls}');
              trace(e);
            }
          }
        }


        var scriptedCharClassNames3:Array<String> = ScriptedAnimateAtlasCharacter.listScriptClasses();
        if (scriptedCharClassNames3.length > 0)
        {
          trace('  Instantiating ${scriptedCharClassNames3.length} (Animate Atlas) scripted characters...');
          for (charCls in scriptedCharClassNames3)
          {
            try
            {
              var character:AnimateAtlasCharacter = ScriptedAnimateAtlasCharacter.init(charCls, DEFAULT_CHAR_ID);
              trace('  Initialized character ${character.characterName}');
              characterScriptedClass.set(character.id, charCls);
            }
            catch (e)
            {
              trace('    FAILED to instantiate scripted Animate Atlas character: ${charCls}');
              trace(e);
            }
          }
        }

        var scriptedCharClassNames:Array<String> = ScriptedBaseCharacter.listScriptClasses();
        scriptedCharClassNames = scriptedCharClassNames.filter(function(charCls:String):Bool {
          return !(scriptedCharClassNames1.contains(charCls)
            || scriptedCharClassNames2.contains(charCls)
            || scriptedCharClassNames3.contains(charCls));
        });
    
        if (scriptedCharClassNames.length > 0)
        {
          trace('  Instantiating ${scriptedCharClassNames.length} (Base) scripted characters...');
          for (charCls in scriptedCharClassNames)
          {
            var character:BaseCharacter = ScriptedBaseCharacter.init(charCls, DEFAULT_CHAR_ID);
            if (character == null)
            {
              trace('    Failed to instantiate scripted character: ${charCls}');
              continue;
            }
            else
            {
              trace('    Successfully instantiated scripted character: ${charCls}');
              characterScriptedClass.set(character.id, charCls);
            }
          }
        }
    
        trace('  Successfully loaded ${Lambda.count(characterCache)} characters.');
    }

    public static function fetchCharacter(charId:String):Null<BaseCharacter>
    {

        if (charId == null || charId == '' || !characterCache.exists(charId))
        {
            // Gracefully handle songs that don't use this character,
            // or throw an error if the character is missing.

            if (charId != null && charId != '') trace('Failed to build character, not found in cache: ${charId}');
            return null;
        }
        
        var charData:CharacterData = characterCache.get(charId);
        var charScriptClass:String = characterScriptedClass.get(charId);
    
        var char:BaseCharacter;
    
        if (charScriptClass != null)
        {
            switch (charData.renderType)
            {
                case CharacterRenderType.AnimateAtlas:
                    char = ScriptedAnimateAtlasCharacter.init(charScriptClass, charId);
                case CharacterRenderType.MultiAtlas:
                    char = ScriptedMultiAtlasCharacter.init(charScriptClass, charId);
                case CharacterRenderType.Atlas: 
                    char = ScriptedAtlasCharacter.init(charScriptClass, charId);
                default:
                    char = ScriptedBaseCharacter.init(charScriptClass, charId);
            }
        }
        else
        {
            switch (charData.renderType)
            {
              case CharacterRenderType.AnimateAtlas:
                char = new AnimateAtlasCharacter(charId);
                case CharacterRenderType.MultiAtlas:
                char = new MultiAtlasCharacter(charId);
              case CharacterRenderType.Atlas:
                char = new AtlasCharacter(charId);
              default:
                trace('[WARN] Creating character with undefined renderType ${charData.renderType}');
                char = new BaseCharacter(charId, CharacterRenderType.Custom);
            }
        }

        if (char == null)
        {
            trace('Failed to instantiate character: ${charId}');
            return null;
        }
        
        trace('Successfully instantiated character: ${charId}');

        ScriptEventDispatcher.callEvent(char, new ScriptEvent(CREATE));

        return char;
    }

    public static function fetchCharacterData(charId:String):Null<CharacterData>
    {
        if (characterCache.exists(charId)) return characterCache.get(charId);
        return null;
    }

    public static function listCharacterIds():Array<String>
    {
        return characterCache.keys().array();
    }

    static function clearCharacterCache():Void
    {
        if (characterCache != null)
            characterCache.clear();
        if (characterScriptedClass != null)
            characterScriptedClass.clear();
    }

    public static function parseCharacterData(charId:String):Null<CharacterData>
    {
        var rawJson:String = loadCharacterFile(charId);
      
        var charData:CharacterData = migrateCharacterData(rawJson, charId);
      
        return validateCharacterData(charId, charData);
    }
      
    static function loadCharacterFile(charPath:String):String
    {
        var charFilePath:String = Paths.json('characters/${charPath}');
        var rawJson = Assets.getText(charFilePath).trim();
      
        while (!StringTools.endsWith(rawJson, '}'))
        {
            rawJson = rawJson.substr(0, rawJson.length - 1);
        }
      
        return rawJson;
    }

    static function migrateCharacterData(rawJson:String, charId:String):Null<CharacterData>
    {
        try
        {
            var charData:CharacterData = cast Json.parse(rawJson);
            return charData;
        }
        catch (e)
        {
            trace('  Error parsing data for character: ${charId}');
            trace('    ${e}');
            return null;
        }
    }

    static function validateCharacterData(id:String, input:CharacterData):Null<CharacterData>
    {
        if (input == null)
        {
            trace('ERROR: Could not parse character data for "${id}".');
            return null;
        }
        
        if (input.version == null)
        {
            trace('WARN: No semantic version specified for character data file "$id", assuming ${CHARACTER_DATA_VERSION}');
            input.version = CHARACTER_DATA_VERSION;
        }
        
        if (!VersionUtil.validateVersionStr(input.version, CHARACTER_DATA_VERSION_RULE))
        {
            trace('ERROR: Could not load character data for "$id": bad version (got ${input.version}, expected ${CHARACTER_DATA_VERSION_RULE})');
            return null;
        }
        
        
        if (input.name == null)
        {
            trace('WARN: Character data for "$id" missing name');
            input.name = "UNKOWN";
        }
        
        if (input.renderType == null)
        {
            input.renderType = CharacterRenderType.Atlas;
        }
        
        if (input.assetPath == null)
        {
            trace('ERROR: Could not load character data for "$id": missing assetPath');
            return null;
        }

        if (input.offsets == null)
            input.offsets = [0, 0];
        
        if (input.cameraOffsets == null)
            input.cameraOffsets = [0, 0];

        if (input.healthIcon == null)
        {
            input.healthIcon =
            {
              id: null,
              scale: null,
              flipX: null,
              antialiasing: null,
              offsets: null
            };            
        }

        if (input.healthIcon.id == null)
            input.healthIcon.id = id;

        if (input.healthIcon.scale == null)
            input.healthIcon.scale = 1;

        if (input.healthIcon.flipX == null)
            input.healthIcon.flipX = false;

        if (input.healthIcon.offsets == null)
            input.healthIcon.offsets = [0, 0];

        if (input.healthIcon.antialiasing == null)
            input.healthIcon.antialiasing = true;

        if (input.scale == null)
            input.scale = 1;

        if (input.antialiasing == null)
            input.antialiasing = true;

        if (input.animations == null || input.animations.length == 0)
        {
            trace('ERROR: Could not load character data for "$id": missing animations');
            input.animations = [];
        }

        if (input.flipX == null)
            input.flipX = false;

        for (inputAnimation in input.animations)
        {
            if (inputAnimation.name == null)
            {
                trace('ERROR: Could not load character data for "$id": missing animation name for prop "${input.name}"');
                return null;
            }
        
            if (inputAnimation.frameRate == null)
                inputAnimation.frameRate = 24;
        
            if (inputAnimation.offsets == null)
                inputAnimation.offsets = [0, 0];
        
            if (inputAnimation.looped == null)
                inputAnimation.looped = false;
        }
        
        // All good!
        return input;
    }
}