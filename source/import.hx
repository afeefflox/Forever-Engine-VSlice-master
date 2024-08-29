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
import meta.Cursor;

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
import meta.data.VideoCutscene;

import meta.data.dependency.Discord;
import meta.data.dependency.FNFSprite;
import meta.data.dependency.FNFTransition;
import meta.data.font.Alphabet;
import meta.data.font.Dialogue;


//Util
import meta.util.JsonUtil.FunkyJson;
import meta.util.*;
import meta.util.assets.*;
import meta.shaders.*;
 
//State
import meta.state.menus.*;
import meta.state.*;
import meta.subState.*;
import meta.ui.*;


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
import flixel.input.mouse.FlxMouseEvent;

//OpenFl
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import openfl.events.KeyboardEvent;
//Haxe UI
import haxe.ui.backend.flixel.UIRuntimeState;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.Frame;
import haxe.ui.containers.Grid;
import haxe.ui.containers.HBox;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.TreeView;
import haxe.ui.containers.TreeViewNode;
import haxe.ui.core.Screen;
import haxe.ui.events.DragEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.focus.FocusManager;
import haxe.ui.Toolkit;
import haxe.ui.containers.ListView;
import haxe.ui.core.Component;
import haxe.ui.RuntimeComponentBuilder;
import haxe.ui.events.UIEvent;


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