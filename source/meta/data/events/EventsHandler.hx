package meta.data.events;

class EventsHandler
{
  static final BUILTIN_EVENTS:List<Class<Events>> = macros.ClassMacro.listSubclassesOf(Events);
    public static var eventsCache:Map<String, Events> = new Map<String, Events>();
    public static function loadModuleCache():Void
    {
        clearModuleCache();
        trace("[EVENTHANDLER] Loading event cache...");
    
        registerBaseEvents();
        registerScriptedEvents();
        eventsCache.keys().array().sort(function(a, b) return Reflect.compare(a.toLowerCase(), b.toLowerCase()));
        trace("[EVENTHANDLER] event cache loaded.");      
    }

    static function registerScriptedEvents()
    {
      var scriptedModuleClassNames:Array<String> = ScriptedEvents.listScriptClasses();
      trace('  Instantiating ${scriptedModuleClassNames.length} events...');
      for (moduleCls in scriptedModuleClassNames)
      {
        var module:Events = ScriptedEvents.init(moduleCls, moduleCls);
        if (module != null)
        {
          trace('    Loaded event: ${moduleCls}');
  
          // Then store it.
          addToModuleCache(module);
        }
        else
        {
          trace('    Failed to instantiate event: ${moduleCls}');
        }
      }
    }

    static function registerBaseEvents()
    {
      trace('Instantiating ${BUILTIN_EVENTS.length} built-in events...');
      for (eventCls in BUILTIN_EVENTS)
      {
        var eventClsName:String = Type.getClassName(eventCls);
        if (eventClsName == 'meta.data.events.Events' || eventClsName == 'meta.data.events.ScriptedEvents') continue;
  
        var event:Events = Type.createInstance(eventCls, ["UNKNOWN"]);
  
        if (event != null)
        {
          trace('  Loaded built-in event: ${event.eventId}');
          eventsCache.set(event.eventId, event);
        }
        else
        {
          trace('  Failed to load built-in event: ${Type.getClassName(eventCls)}');
        }
      }
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