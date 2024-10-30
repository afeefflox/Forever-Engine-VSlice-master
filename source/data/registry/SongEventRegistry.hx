package data.registry;

import meta.data.events.ScriptedSongEvent;

class SongEventRegistry
{
    static final BUILTIN_EVENTS:List<Class<SongEvent>> = macros.ClassMacro.listSubclassesOf(SongEvent);
    static final eventCache:Map<String, SongEvent> = new Map<String, SongEvent>();

    public static function loadEventCache():Void
    {
        clearEventCache();

        registerBaseEvents();
        registerScriptedEvents();
    }

    static function registerBaseEvents()
    {
        trace('Instantiating ${BUILTIN_EVENTS.length} built-in song events...');
        for (eventCls in BUILTIN_EVENTS)
        {
            var eventClsName:String = Type.getClassName(eventCls);
            if (eventClsName == 'meta.data.events.SongEvent' || eventClsName == 'meta.data.events.ScriptedSongEvent') continue;

            var event:SongEvent = Type.createInstance(eventCls, ["UNKNOWN"]);

            if (event != null)
            {
                trace('  Loaded built-in song event: ${event.id}');
                eventCache.set(event.id, event);
            }
            else
                trace('  Failed to load built-in song event: ${Type.getClassName(eventCls)}');
        }
    }

    static function registerScriptedEvents()
    {
        var scriptedEventClassNames:Array<String> = ScriptedSongEvent.listScriptClasses();
        trace('Instantiating ${scriptedEventClassNames.length} scripted song events...');
        if (scriptedEventClassNames == null || scriptedEventClassNames.length == 0) return;

        for (eventCls in scriptedEventClassNames)
        {
            var event:SongEvent = ScriptedSongEvent.init(eventCls, "UKNOWN");

            if (event != null)
            {
                trace('  Loaded scripted song event: ${event.id}');
                eventCache.set(event.id, event);
            }
            else
                trace('  Failed to instantiate scripted song event class: ${eventCls}');
        }
    }

    public static function listEventIds():Array<String> return eventCache.keys().array();
    public static function listEvents():Array<SongEvent> return eventCache.values();
    public static function getEvent(id:String):SongEvent   return eventCache.get(id);
    public static function getEventSchema(id:String):SongEventSchema 
    {
        var event:SongEvent = getEvent(id);
        if (event == null) return null;
    
        return event.getEventSchema();
    }
    static function clearEventCache() eventCache.clear();
    public static function handleEvent(data:SongEventData):Void
    {
        var eventKind:String = data.eventKind;
        var eventHandler:SongEvent = eventCache.get(eventKind);
    
        if (eventHandler != null) 
            eventHandler.handleEvent(data);
        else
            trace('WARNING: No event handler for event with kind: ${eventKind}');
        data.activated = true;
    }

    public static inline function handleEvents(events:Array<SongEventData>):Void
    {
        for (event in events) handleEvent(event);
    }

    public static function queryEvents(events:Array<SongEventData>, currentTime:Float):Array<SongEventData>
    {
        return events.filter(function(event:SongEventData):Bool {
            if (event.activated) return false;
            if (event.time > currentTime) return false;
            return true;
        });
    }

    public static function handleSkippedEvents(events:Array<SongEventData>, currentTime:Float):Void
    {
        for (event in events) event.activated = (event.time < currentTime) ? true : false;
    }
    
    public static function resetEvents(events:Array<SongEventData>):Void 
    {
        for (event in events) event.activated = false;
    }
}