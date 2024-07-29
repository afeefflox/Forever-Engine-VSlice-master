package gameObjects.character;

@:hscriptClass
class ScriptedBaseCharacter extends gameObjects.character.BaseCharacter implements polymod.hscript.HScriptedClass {}

@:hscriptClass
class ScriptedAtlasCharacter extends gameObjects.character.AtlasCharacter implements polymod.hscript.HScriptedClass {}


@:hscriptClass
class ScriptedMultiAtlasCharacter extends gameObjects.character.MultiAtlasCharacter implements polymod.hscript.HScriptedClass {}


@:hscriptClass
class ScriptedAnimateAtlasCharacter extends gameObjects.character.AnimateAtlasCharacter implements polymod.hscript.HScriptedClass {}

