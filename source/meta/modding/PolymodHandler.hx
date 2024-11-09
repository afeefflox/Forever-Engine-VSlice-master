package meta.modding;

import polymod.fs.ZipFileSystem;
import meta.modding.module.ModuleHandler;
import polymod.backends.PolymodAssets.PolymodAssetType;
import polymod.format.ParseRules.TextFileFormat;
import polymod.Polymod;

/**
 * A class for interacting with Polymod, the atomic modding framework for Haxe.
 */
class PolymodHandler
{
  /**
   * The API version that mods should comply with.
   * Format this with Semantic Versioning; <MAJOR>.<MINOR>.<PATCH>.
   * Bug fixes increment the patch version, new features increment the minor version.
   * Changes that break old mods increment the major version.
   */
  static final API_VERSION:String = '0.1.0';

  /**
   * Where relative to the executable that mods are located.
   */
  public static var loadedModIds:Array<String> = [];

  // Use SysZipFileSystem on desktop and MemoryZipFilesystem on web.
  static var modFileSystem:Null<ZipFileSystem> = null;

  /**
   * If the mods folder doesn't exist, create it.
   */
  public static function createModRoot():Void
  {
    FileUtil.createDirIfNotExists('mods');
  }

  /**
   * Loads the game with ALL mods enabled with Polymod.
   */
  public static function loadAllMods():Void
  {
    // Create the mod root if it doesn't exist.
    createModRoot();
    trace('Initializing Polymod (using all mods)...');
    loadModsById(getAllModIds(), 'mods');
  }

  public static function loadCurrentMods():Void
  {
    createModRoot();
    trace('Initializing Polymod (using configured mods)...');
    loadModsById([Init.trueSettings.get('Current Mod')], 'mods');
  }

  public static function loadNoMods():Void
  {
    createModRoot();
    // We still need to configure the debug print calls etc.
    trace('Initializing Polymod (using no mods)...');
    loadModsById([], 'mods');
  }

  public static function loadAllonAddons():Void
  {
    FileUtil.createDirIfNotExists('addons');
    loadModsById(getAllModIds('addons'), 'addons');
  }
  /**
   * Load all the mods with the given ids.
   * @param ids The ORDERED list of mod ids to load.
   */
  public static function loadModsById(ids:Array<String>, ?root:String = 'aaa'):Void
  {
    if (ids.length == 0)
    {
      trace('You attempted to load zero ${root}.');
    }
    else
    {
      trace('Attempting to load ${ids.length} ${root}...');
    }

    buildImports();

    if (modFileSystem == null) modFileSystem = buildFileSystem(root);

    var prefix:String = "";
    if(root != 'mods') prefix = './';

    var loadedModList:Array<ModMetadata> = Polymod.init(
      {
        // Root directory for all mods.
        modRoot: prefix + root,
        // The directories for one or more mods to load.
        dirs: ids,
        // Framework being used to load assets.
        framework: OPENFL,
        // The current version of our API.
        apiVersionRule: API_VERSION,
        // Call this function any time an error occurs.
        errorCallback: PolymodErrorHandler.onPolymodError,
        customFilesystem: modFileSystem,

        // List of filenames to ignore in mods. Use the default list to ignore the metadata file, etc.
        ignoredFiles: Polymod.getDefaultIgnoreList(),

        // Parsing rules for various data formats.
        parseRules: buildParseRules(),

        // Parse hxc files and register the scripted classes in them.
        useScriptedClasses: true
      });
      

    if (loadedModList == null)
    {
      trace('An error occurred! Failed when loading ${root}!');
    }
    else
    {
      if (loadedModList.length == 0)
      {
        trace('Mod loading complete. We loaded no ${root} / ${ids.length} ${root}.');
      }
      else
      {
        trace('Mod loading complete. We loaded ${loadedModList.length} / ${ids.length} ${root}.');
      }
    }

    loadedModIds = [];
    for (mod in loadedModList)
    {
      trace('  * ${mod.title} v${mod.modVersion} [${mod.id}]');
      loadedModIds.push(mod.id);
    }
  }

  public static function loadAddonsById(ids:Array<String>, ?root:String = 'aaa'):Void
  {

  }

  static function buildFileSystem(?root:String = "aaa"):polymod.fs.ZipFileSystem
  {
    var prefix:String = "";
    if(root != 'mods') prefix = './';
      
    polymod.Polymod.onError = PolymodErrorHandler.onPolymodError;
    return new ZipFileSystem({modRoot: prefix + root, autoScan: true});
  }

  static function buildParseRules():polymod.format.ParseRules
  {
    var output:polymod.format.ParseRules = polymod.format.ParseRules.getDefault();
    // Ensure TXT files have merge support.
    output.addType('txt', TextFileFormat.LINES);
    // Ensure script files have merge support.
    output.addType('hscript', TextFileFormat.PLAINTEXT);
    output.addType('hxs', TextFileFormat.PLAINTEXT);
    output.addType('hxc', TextFileFormat.PLAINTEXT);
    output.addType('hx', TextFileFormat.PLAINTEXT);

    // You can specify the format of a specific file, with file extension.
    // output.addFile("data/introText.txt", TextFileFormat.LINES)
    return output;
  }

  /**
   * Retrieve a list of metadata for ALL installed mods, including disabled mods.
   * @return An array of mod metadata
   */
  public static function getAllMods(?root:String = 'aaa'):Array<ModMetadata>
  {
    trace('Scanning the ${root} folder...');

    if (modFileSystem == null) modFileSystem = buildFileSystem(root);

    var prefix:String = "";
    if(root != 'mods') prefix = './';

    var modMetadata:Array<ModMetadata> = Polymod.scan(
      {
        modRoot: prefix + root,
        apiVersionRule: API_VERSION,
        fileSystem: modFileSystem,
        errorCallback: PolymodErrorHandler.onPolymodError
      });
    trace('Found ${modMetadata.length} ${root} when scanning.');
    return modMetadata;
  }

  static function buildImports():Void
  {
    Polymod.addImportAlias('flixel.math.FlxPoint', Type.resolveClass('flixel.math.FlxPoint_HSC'));
    Polymod.addImportAlias('flixel.util.FlxAxes', Type.resolveClass('flixel.util.FlxAxes_HSC'));
    Polymod.addImportAlias('flixel.util.FlxColor', Type.resolveClass('flixel.util.FlxColor_HSC'));
    Polymod.addDefaultImport(Init);
    Polymod.addDefaultImport(Paths);
    Polymod.addDefaultImport(ForeverAssets);
    Polymod.addDefaultImport(ForeverTools);
  }

  /**
   * Retrieve a list of ALL mod IDs, including disabled mods.
   * @return An array of mod IDs
   */
  public static function getAllModIds(?root:String = "aaa"):Array<String>
  {
    var modIds:Array<String> = [for (i in getAllMods(root)) i.id];
    return modIds;
  }
  
  
  /**
   * Clear and reload from disk all data assets.
   * Useful for "hot reloading" for fast iteration!
   */
  public static function forceReloadAssets():Void
  {
    // Forcibly clear scripts so that scripts can be edited.
    ModuleHandler.clearModuleCache();
    Polymod.clearScripts();

    PolymodHandler.loadCurrentMods();
		//PolymodHandler.loadAllonAddons();

    // Reload scripted classes so stages and modules will update.
    Polymod.registerAllScriptClasses();

    // Reload everything that is cached.
    // Currently this freezes the game for a second but I guess that's tolerable?

    // TODO: Reload event callbacks

    // These MUST be imported at the top of the file and not referred to by fully qualified name,
    // to ensure build macros work properly.

		//BaseRegistry
		SongRegistry.instance.loadEntries();
		LevelRegistry.instance.loadEntries();
		NoteStyleRegistry.instance.loadEntries();
		PlayerRegistry.instance.loadEntries();
		StageRegistry.instance.loadEntries();
		AlbumRegistry.instance.loadEntries();
		FreeplayStyleRegistry.instance.loadEntries();

		//Non BaseRegistry
		SongEventRegistry.loadEventCache();
		NoteKindManager.loadScripts();
		CharacterRegistry.loadCharacterCache();
  }
}
