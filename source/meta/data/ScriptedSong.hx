package meta.data;

import polymod.hscript.HScriptedClass;
/**
 * A script that can be tied to a Module, which persists across states.
 * Create a scripted class that extends Module to use this.
 */
@:hscriptClass
class ScriptedSong extends meta.data.Song implements HScriptedClass {}