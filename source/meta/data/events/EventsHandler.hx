package meta.data.events;

class EventsHandler
{
    public static var eventsCache:Map<String, Events> = new Map<String, Events>();
    public static function loadModuleCache():Void
    {
        clearModuleCache();
        trace("[EVENTHANDLER] Loading event cache...");
    
        var scriptedModuleClassNames:Array<String> = ScriptedEvents.listScriptClasses();
        trace('  Instantiating ${scriptedModuleClassNames.length} events...');
        for (moduleCls in scriptedModuleClassNames)
        {
          var module:Events = ScriptedEvents.init(moduleCls, moduleCls);
          if (module != null)
          {
            trace('    Loaded module: ${moduleCls}');
    
            // Then store it.
            addToModuleCache(module);
          }
          else
          {
            trace('    Failed to instantiate module: ${moduleCls}');
          }
        }
        eventsCache.keys().array().sort(function(a, b) return Reflect.compare(a.toLowerCase(), b.toLowerCase()));
        trace("[EVENTHANDLER] event cache loaded.");        
    }

    public static function clearModuleCache():Void
    {
        if (eventsCache != null)
            eventsCache.clear();
    }

    static function addToModuleCache(module:Events):Void
    {
        eventsCache.set(module.eventId, module);
    }

    public static function getEvents(moduleId:String):Events
    {
      return eventsCache.get(moduleId);
    }

    public static function existsEvents(moduleId:String):Bool
    {
      return eventsCache.exists(moduleId);
    }

}