package meta.data.events;

import polymod.hscript.HScriptedClass;

/**
 * A script that can be tied to a Module, which persists across states.
 * Create a scripted class that extends Module to use this.
 */
@:hscriptClass
class ScriptedEvents extends meta.data.events.Events implements HScriptedClass {}