package;

#if !macro
//Modding
import meta.modding.PolymodHandler;
import meta.modding.events.ScriptEvent;
import meta.modding.events.ScriptEventDispatcher;
import meta.modding.events.ScriptEventType;
import meta.modding.module.ModuleHandler;

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
import gameObjects.userInterface.notes.NoteSprite;
import gameObjects.userInterface.notes.notestyle.NoteStyle;
import gameObjects.userInterface.notes.notekind.NoteKindManager;
import gameObjects.userInterface.notes.NoteDirection;
import gameObjects.userInterface.notes.StrumlineNote;
import gameObjects.userInterface.notes.SustainTrail;
import gameObjects.userInterface.notes.NoteSplash;
import gameObjects.userInterface.notes.Strumline;
import gameObjects.userInterface.menu.Checkmark;
import gameObjects.userInterface.Countdown;
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
import meta.TurboButtonHandler;
import meta.TurboKeyHandler;

//Base
import data.registry.base.BaseRegistry;
import data.registry.base.IRegistryEntry;

//Data
import data.AnimationData;
import data.CharacterData;
import data.LevelData;
import data.StageData;
import data.NoteStyleData;
import data.PlayerData;

//Registry
import data.registry.LevelRegistry;
import data.registry.CharacterRegistry;
import data.registry.StageRegistry;
import data.registry.NoteStyleRegistry;
import data.registry.SongRegistry;
import data.registry.SongEventRegistry;
import data.registry.PlayerRegistry;

//SONG DATA
import data.SongData.SongMetadata;
import data.SongData.SongTimeFormat;
import data.SongData.SongTimeChange;
import data.SongData.SongOffsets;
import data.SongData.SongPlayData;
import data.SongData.SongCharacterData;
import data.SongData.SongChartData;
import data.SongData.SongEventData;
import data.SongData.SongNoteData;
import data.SongData.NoteParamData;
import data.SongData.SongMusicData;
import data.SongEventSchema;
import data.SongEventSchema.SongEventFieldType;
import data.SongDataUtils;

//IMPORTER
import data.importer.MaruImporter;
import data.importer.LegacyImporter;
import data.importer.ChartManifestData;

//Metadata
import meta.data.Song;
import meta.data.PlayableCharacter;
import meta.data.SongSerializer;
import meta.data.events.SongEvent;
import meta.data.Conductor;
import meta.data.Highscore;
import meta.data.PlayerSettings;
import meta.data.Timings;
import meta.data.VideoCutscene;

import meta.data.dependency.Discord;
import meta.data.dependency.FNFSprite;
import meta.data.dependency.FNFTransition;
import meta.data.font.Alphabet;
import meta.data.font.Dialogue;
import meta.data.PlayStateData.PlayStatePlaylist;
import meta.data.PlayStateData.PlayStateParams;

//Graphics
import graphics.shaders.*;
import graphics.*;

//Audio
import audio.*;

//Util
import meta.util.JsonUtil.FunkyJson;
import meta.util.*;
import meta.util.assets.*;

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
import openfl.utils.Assets;
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