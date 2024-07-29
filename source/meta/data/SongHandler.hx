package meta.data;

class SongHandler {
    public static var songCache:Map<String, Song> = new Map<String, Song>();
    public static function loadModuleCache():Void
    {
        clearModuleCache();
        trace("[SONGHANDLER] Loading song cache...");
        var scriptedModuleClassNames:Array<String> = ScriptedSong.listScriptClasses();
        trace('  Instantiating ${scriptedModuleClassNames.length} songs...');
        {
            for (moduleCls in scriptedModuleClassNames)
            {
                var module:Song = ScriptedSong.init(moduleCls, moduleCls);
                if (module != null)
                {
                  trace('    Loaded module: ${moduleCls}');
          
                  // Then store it.
                  addToModuleCache(module);
                }
                else
                    trace('    Failed to instantiate module: ${moduleCls}');
            }
        }
        trace("[SONGHANDLER] song cache loaded.");        
    }

    public static function clearModuleCache():Void
    {
        if (songCache != null)
            songCache.clear();
    }

    static function addToModuleCache(module:Song):Void
    {
        songCache.set(module.id, module);
    }

    public static function getSong(moduleId:String):Song
    {
        return songCache.get(moduleId);
    }

    public static function existsSong(moduleId:String):Bool
    {
        return songCache.exists(moduleId);
    }
}