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
    loadModsById(getAllModIds());
  }
  /**
   * Load all the mods with the given ids.
   * @param ids The ORDERED list of mod ids to load.
   */
  public static function loadModsById(ids:Array<String>):Void
  {
    if (ids.length == 0)
    {
      trace('You attempted to load zero mods.');
    }
    else
    {
      trace('Attempting to load ${ids.length} mods...');
    }

    //buildImports();

    if (modFileSystem == null) modFileSystem = buildFileSystem();

    var loadedModList:Array<ModMetadata> = Polymod.init(
      {
        // Root directory for all mods.
        modRoot: "mods",
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
      trace('An error occurred! Failed when loading mods!');
    }
    else
    {
      if (loadedModList.length == 0)
      {
        trace('Mod loading complete. We loaded no mods / ${ids.length} mods.');
      }
      else
      {
        trace('Mod loading complete. We loaded ${loadedModList.length} / ${ids.length} mods.');
      }
    }

    loadedModIds = [];
    for (mod in loadedModList)
    {
      trace('  * ${mod.title} v${mod.modVersion} [${mod.id}]');
      loadedModIds.push(mod.id);
    }

    #if debug
    var fileList:Array<String> = Polymod.listModFiles(PolymodAssetType.IMAGE);
    trace('Installed mods have replaced ${fileList.length} images.');
    for (item in fileList)
    {
      trace('  * $item');
    }

    fileList = Polymod.listModFiles(PolymodAssetType.TEXT);
    trace('Installed mods have added/replaced ${fileList.length} text files.');
    for (item in fileList)
    {
      trace('  * $item');
    }

    fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_MUSIC);
    trace('Installed mods have replaced ${fileList.length} music files.');
    for (item in fileList)
    {
      trace('  * $item');
    }

    fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_SOUND);
    trace('Installed mods have replaced ${fileList.length} sound files.');
    for (item in fileList)
    {
      trace('  * $item');
    }

    fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_GENERIC);
    trace('Installed mods have replaced ${fileList.length} generic audio files.');
    for (item in fileList)
    {
      trace('  * $item');
    }
    #end
  }

  static function buildFileSystem():polymod.fs.ZipFileSystem
  {
    polymod.Polymod.onError = PolymodErrorHandler.onPolymodError;
    return new ZipFileSystem(
      {
        modRoot: "mods",
        autoScan: true
      });
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
  public static function getAllMods():Array<ModMetadata>
  {
    trace('Scanning the mods folder...');

    if (modFileSystem == null) modFileSystem = buildFileSystem();

    var modMetadata:Array<ModMetadata> = Polymod.scan(
      {
        modRoot: "mods",
        apiVersionRule: API_VERSION,
        fileSystem: modFileSystem,
        errorCallback: PolymodErrorHandler.onPolymodError
      });
    trace('Found ${modMetadata.length} mods when scanning.');
    return modMetadata;
  }

  /**
   * Retrieve a list of ALL mod IDs, including disabled mods.
   * @return An array of mod IDs
   */
  public static function getAllModIds():Array<String>
  {
    var modIds:Array<String> = [for (i in getAllMods()) i.id];
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

    // Forcibly reload Polymod so it finds any new files.
    // TODO: Replace this with loadEnabledMods().
    PolymodHandler.loadAllMods();

    // Reload scripted classes so stages and modules will update.
    Polymod.registerAllScriptClasses();

    // Reload everything that is cached.
    // Currently this freezes the game for a second but I guess that's tolerable?

    // TODO: Reload event callbacks

    // These MUST be imported at the top of the file and not referred to by fully qualified name,
    // to ensure build macros work properly.
    NoteTypeRegistry.instance.loadEntries();
    SongHandler.loadModuleCache();
    LevelRegistry.instance.loadEntries();
    StageRegistry.instance.loadEntries();
    EventsHandler.loadModuleCache();
    CharacterRegistry.loadCharacterCache(); // TODO: Migrate characters to BaseRegistry.
    ModuleHandler.loadModuleCache();
  }
}
