#if !macro

//Modding
import meta.modding.PolymodHandler;
import meta.modding.events.ScriptEvent;
import meta.modding.events.ScriptEventDispatcher;
import meta.modding.events.ScriptEventType;
import meta.modding.module.ModuleHandler;
import meta.data.events.EventsHandler;
import meta.data.events.Events;
import meta.data.events.ScriptedEvents;
import meta.data.SongHandler;

//IScriptedClass
import meta.modding.IScriptedClass;
import meta.modding.IScriptedClass.IEventHandler;
import meta.modding.IScriptedClass.IStateChangingScriptedClass;
import meta.modding.IScriptedClass.IStateStageProp;
import meta.modding.IScriptedClass.INoteScriptedClass;
import meta.modding.IScriptedClass.IPlayStateScriptedClass;

//UI
import gameObjects.userInterface.HealthIcon;
import gameObjects.userInterface.ClassHUD;
import gameObjects.userInterface.DialogueBox;
import gameObjects.userInterface.notes.Note;
import gameObjects.userInterface.notes.NoteSplash;
import gameObjects.userInterface.notes.Strumline;
import gameObjects.userInterface.menu.Checkmark;
import gameObjects.userInterface.menu.DebugUI;
import gameObjects.userInterface.menu.Selector;

//gameObjects
import gameObjects.character.BaseCharacter;
import gameObjects.character.*;
import gameObjects.stage.Stage;
import gameObjects.stage.*;
//Meta
import meta.Controls;
import meta.CoolUtil;
import meta.Overlay;

//Data
import data.AnimationData;
import data.CharacterData;
import data.LevelData;
import data.StageData;
import data.registry.LevelRegistry;
import data.registry.CharacterRegistry;
import data.registry.StageRegistry;
import data.registry.NoteTypeRegistry;

import meta.data.Song;
import meta.data.Song.SwagSection;
import meta.data.Conductor;
import meta.data.Conductor;
import meta.data.ChartLoader;
import meta.data.Highscore;
import meta.data.PlayerSettings;
import meta.data.Timings;

import meta.data.dependency.Discord;
import meta.data.dependency.FNFSprite;
import meta.data.dependency.FNFTransition;
import meta.data.font.Alphabet;
import meta.data.font.Dialogue;


//Util
import meta.util.*;
import meta.util.assets.*;

//State
import meta.MusicBeat.MusicBeatState;
import meta.MusicBeat.MusicBeatSubState;
import meta.state.menus.*;
import meta.state.*;
import meta.subState.*;


//Haxeflixel shit
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import openfl.geom.Rectangle;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.FlxState;
import flixel.math.FlxAngle;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxArrayUtil;

//FlxAnimate
import flxanimate.FlxAnimate;

import haxe.Json;

using Lambda;
using StringTools;
using thx.Arrays;
using meta.util.tools.ArraySortTools;
using meta.util.tools.ArrayTools;
using meta.util.tools.FloatTools;
using meta.util.tools.Int64Tools;
using meta.util.tools.IntTools;
using meta.util.tools.IteratorTools;
using meta.util.tools.MapTools;
using meta.util.tools.StringTools;
#end