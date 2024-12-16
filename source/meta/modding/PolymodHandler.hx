package meta.modding;

import polymod.backends.OpenFLBackend;
import polymod.backends.PolymodAssets.PolymodAssetType;
import polymod.format.ParseRules.LinesParseFormat;
import polymod.format.ParseRules.TextFileFormat;
import polymod.format.ParseRules;
import polymod.Polymod;
//**Just Rewrite Polymod Handle From Kade Engine**/
class PolymodHandler
{
    
    public static function initialize():Void
    {
        initPolymod();
        Polymod.loadOnlyMods(Init.trueSettings.get('Enabled Mods'));
    }

    public static function initPolymod()
    {
        buildImports();
        
        Polymod.init({
            modRoot: "mods",
            dirs: [],
            framework: OPENFL,
            errorCallback: PolymodErrorHandler.onPolymodError,
            ignoredFiles: Polymod.getDefaultIgnoreList(),
            parseRules: getParseRules(),
			customFilesystem: polymod.fs.SysFileSystem,
            useScriptedClasses: true
        });
    }

    static function buildImports():Void
    {
        Polymod.addImportAlias('flixel.math.FlxPoint', Type.resolveClass('flixel.math.FlxPoint_HSC'));
        Polymod.addImportAlias('flixel.util.FlxAxes', Type.resolveClass('flixel.util.FlxAxes_HSC'));
        Polymod.addImportAlias('flixel.util.FlxColor', Type.resolveClass('flixel.util.FlxColor_HSC'));

        Polymod.addDefaultImport(Init);
        Polymod.addDefaultImport(ForeverAssets);
        Polymod.addDefaultImport(ForeverTools);
        Polymod.addDefaultImport(Paths);
    }

    public static function getAllMods():Array<ModMetadata>
    {
        var daList:Array<ModMetadata> = [];

        for (mod in Polymod.scan({modRoot: 'mods', errorCallback: PolymodErrorHandler.onPolymodError}))
        {
            if (mod != null) daList.push(mod);
        }
        return daList != null && daList.length > 0 ? daList : [];
    }

    static function getParseRules():polymod.format.ParseRules
    {
        var output:ParseRules = ParseRules.getDefault();
        output.addType('txt', TextFileFormat.LINES);
        output.addType('hscript', TextFileFormat.PLAINTEXT);
        output.addType('hxs', TextFileFormat.PLAINTEXT);
        output.addType('hxc', TextFileFormat.PLAINTEXT);
        output.addType('hx', TextFileFormat.PLAINTEXT);
        return output;
    }

    public static function forceReloadAssets():Void
    {
        ModuleHandler.clearModuleCache();
        Polymod.clearScripts();
        PolymodHandler.initialize();    
        Polymod.registerAllScriptClasses();
        
		//BaseRegistry
        SongRegistry.instance.loadEntries();
        LevelRegistry.instance.loadEntries();
        NoteStyleRegistry.instance.loadEntries();
        PlayerRegistry.instance.loadEntries();
        AlbumRegistry.instance.loadEntries();
        StageRegistry.instance.loadEntries();
        
		//Non BaseRegistry
		SongEventRegistry.loadEventCache();
		NoteKindManager.loadScripts();
		CharacterRegistry.loadCharacterCache();
        ModuleHandler.loadModuleCache();
    }
}