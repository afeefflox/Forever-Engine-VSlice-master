package meta.subState;

import flixel.util.typeLimit.NextState;
import haxe.io.Path;
import lime.app.Future;
import lime.app.Promise;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets as LimeAssets;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets as OpenFLAssets;

class LoadingSubState extends MusicBeatSubState
{
    inline static var MIN_TIME = 1.0;

    var asSubState:Bool = false;
  
    var target:NextState;
    var playParams:Null<PlayStateParams>;
    var stopMusic:Bool = false;
    var callbacks:MultiCallback;
    var danceLeft:Bool = false;
  
    var loadBar:FunkinSprite;
    var funkay:FunkinSprite;

    function new(target:NextState, stopMusic:Bool, playParams:Null<PlayStateParams> = null)
    {
        super();
        this.target = target;
        this.playParams = playParams;
        this.stopMusic = stopMusic;
    }
    
    override function create():Void
    {
        funkay = new FunkinSprite().loadImage('menus/base/menuBGBlue');
        funkay.setGraphicSize(FlxG.width, FlxG.height);
        funkay.updateHitbox();
        add(funkay);
        funkay.scrollFactor.set();
        funkay.screenCenter();

        loadBar = new FunkinSprite(0, FlxG.height - 20).makeSolidColor(0, 10, 0xFFff16d2);
        add(loadBar);

        initSongsManifest().onComplete(function(lib) {
            callbacks = new MultiCallback(onLoad);
            var introComplete = callbacks.add('introComplete');
      
            if (playParams != null)
            {
                if (playParams.targetSong != null) playParams.targetSong.cacheCharts(true);

                var difficulty:String = playParams.targetDifficulty ?? Constants.DEFAULT_DIFFICULTY;
                var variation:String = playParams.targetVariation ?? Constants.DEFAULT_VARIATION;
                var targetChart:SongDifficulty = playParams.targetSong?.getDifficulty(difficulty, variation);
                var instPath:String = targetChart.getInstPath(playParams.targetInstrumental);
                var voicesPaths:Array<String> = targetChart.buildVoiceList();
        
                checkLoadSong(instPath);
                for (voicePath in voicesPaths) checkLoadSong(voicePath);
            }

            var fadeTime:Float = 0.5;
            FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
            new FlxTimer().start(fadeTime + MIN_TIME, function(_) introComplete());
        });
    }

    function checkLoadSong(path:String):Void
    {
        if (!OpenFLAssets.cache.hasSound(path))
        {
            var library = Assets.getLibrary('songs');
            var symbolPath = path.split(':').pop();
            var callback = callbacks.add('song:' + path);
            Assets.loadSound(path).onComplete(function(_) {
                callback();
            });
        }
    }

    function checkLibrary(library:String):Void
    {
        trace(Assets.hasLibrary(library));
        if (Assets.getLibrary(library) == null)
        {
            @:privateAccess
            if (!LimeAssets.libraryPaths.exists(library)) throw 'Missing library: ' + library;
        
            var callback = callbacks.add('library:' + library);
            Assets.loadLibrary(library).onComplete(function(_) {
                callback();
            });
        }
    }

    var targetShit:Float = 0;

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        funkay.setGraphicSize(Std.int(FlxMath.lerp(FlxG.width * 0.88, funkay.width, 0.9)));
        funkay.updateHitbox();
        
        if (controls.ACCEPT)
        {
            funkay.setGraphicSize(Std.int(funkay.width + 60));
            funkay.updateHitbox();
        }

        if (callbacks != null)
        {
            targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);

            var lerpWidth:Int = Std.int(FlxMath.lerp(loadBar.width, FlxG.width * targetShit, 0.2));
            if (lerpWidth > 0)
            {
                loadBar.setGraphicSize(lerpWidth, loadBar.height);
                loadBar.updateHitbox();
            }
        }
    }

    function onLoad():Void
    {
        if (stopMusic && FlxG.sound.music != null)
        {
            FlxG.sound.music.destroy();
            FlxG.sound.music = null;
        }

        if (asSubState)
        {
            this.close();
            FlxG.state.openSubState(cast target);
        }
        else
        {
            FlxG.switchState(target);
        }
    }

    static function getSongPath():String return Paths.inst(PlayState.instance.currentSong.id);
    static var stageDirectory:String = "";
    public static function loadPlayState(params:PlayStateParams, shouldStopMusic = false, ?asSubState = false, ?onConstruct:PlayState->Void):Void
    {
        var daChart = params.targetSong.getDifficulty(params.targetDifficulty ?? Constants.DEFAULT_DIFFICULTY, params.targetVariation ?? Constants.DEFAULT_VARIATION);

        var daStage = StageRegistry.instance.fetchEntry(daChart.stage);
        stageDirectory = daStage?._data?.library ?? "";
        Paths.setCurrentLevel(stageDirectory);

        var playStateCtor:() -> PlayState = function() {
            return new PlayState(params);
        };

        if (onConstruct != null)
        {
            playStateCtor = function() {
                var result = new PlayState(params);
                onConstruct(result);
                return result;
            };
        }

        if (shouldStopMusic && FlxG.sound.music != null)
        {
            FlxG.sound.music.destroy();
            FlxG.sound.music = null;
        }

        if (params?.targetSong != null && !params.overrideMusic) params.targetSong.cacheCharts(true);
        var shouldPreloadLevelAssets:Bool = !(params?.minimalMode ?? false);
        if (shouldPreloadLevelAssets) preloadLevelAssets();

        if (asSubState)
            FlxG.state.openSubState(cast playStateCtor());
        else
            FlxG.switchState(playStateCtor);
    }

    static function preloadLevelAssets():Void
    {
        FunkinSprite.preparePurgeCache();
        FunkinSprite.cacheTexture(Paths.image('UI/base/healthBar'));
        FunkinSprite.cacheTexture(Paths.image('menus/base/menuDesat'));

        FunkinSprite.cacheTexture(Paths.image('UI/base/combo'));
        FunkinSprite.cacheTexture(Paths.image('UI/base/judgements'));
        FunkinSprite.cacheTexture(Paths.image('UI/base/ready'));
        FunkinSprite.cacheTexture(Paths.image('UI/base/set'));
        FunkinSprite.cacheTexture(Paths.image('UI/base/go'));

        FunkinSprite.cacheTexture(Paths.image('UI/pixel/combo'));
        FunkinSprite.cacheTexture(Paths.image('UI/pixel/judgements'));
        FunkinSprite.cacheTexture(Paths.image('UI/pixel/ready'));
        FunkinSprite.cacheTexture(Paths.image('UI/pixel/set'));
        FunkinSprite.cacheTexture(Paths.image('UI/pixel/go'));

        FunkinSprite.cacheTexture(Paths.image('noteskins/notes/base/NOTE_assets'));
        FunkinSprite.cacheTexture(Paths.image('noteskins/notes/base/NOTE_assetsENDS'));
        FunkinSprite.cacheTexture(Paths.image('noteskins/notes/base/holdCover'));
        FunkinSprite.cacheTexture(Paths.image('noteskins/notes/base/noteSplashes'));

        FunkinSprite.cacheTexture(Paths.image('noteskins/notes/pixel/arrows-pixels'));
        FunkinSprite.cacheTexture(Paths.image('noteskins/notes/pixel/arrowEnds'));

        var library = PlayStatePlaylist.campaignId != null ? openfl.utils.Assets.getLibrary(PlayStatePlaylist.campaignId) : null;
        if (library == null) return; // We don't need to do anymore precaching.

        var assets = library.list(lime.utils.AssetType.IMAGE);
        trace('Got ${assets.length} assets: ${assets}');

        for (asset in assets)
        {
            var path = '${PlayStatePlaylist.campaignId}:${asset}';
            // TODO DUMB HACK DUMB HACK why doesn't filtering by AssetType.IMAGE above work
            // I will fix this properly later I swear -eric
            if (!path.endsWith('.png')) continue;

            new Future<String>(function() {
                FunkinSprite.cacheTexture(path);
                // Another dumb hack: FlxAnimate fetches from OpenFL's BitmapData cache directly and skips the FlxGraphic cache.
                // Since FlxGraphic tells OpenFL to not cache it, we have to do it manually.
                if (path.endsWith('spritemap1.png'))
                {
                  trace('Preloading FlxAnimate asset: ${path}');
                  openfl.Assets.getBitmapData(path, true);
                }
                return 'Done precaching ${path}';
            }, true);
        
            trace('Queued ${path} for precaching');
        }

        FunkinSprite.purgeCache();
    }

    override function destroy():Void
    {
        super.destroy();

        callbacks = null;
    }

    static function initSongsManifest():Future<AssetLibrary>
    {
        var id = 'songs';
        var promise = new Promise<AssetLibrary>();
    
        var library = LimeAssets.getLibrary(id);
    
        if (library != null) return Future.withValue(library);
        var path = id;
        var rootPath = null;

        @:privateAccess
        var libraryPaths = LimeAssets.libraryPaths;
        if (libraryPaths.exists(id))
        {
          path = libraryPaths[id];
          rootPath = Path.directory(path);
        }
        else
        {
          if (path.endsWith('.bundle'))
          {
            rootPath = path;
            path += '/library.json';
          }
          else
          {
            rootPath = Path.directory(path);
          }
          @:privateAccess
          path = LimeAssets.__cacheBreak(path);
        }
        
        AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest) {
            if (manifest == null)
            {
              promise.error('Cannot parse asset manifest for library \'' + id + '\'');
              return;
            }
      
            var library = AssetLibrary.fromManifest(manifest);
      
            if (library == null)
            {
              promise.error('Cannot open library \'' + id + '\'');
            }
            else
            {
              @:privateAccess
              LimeAssets.libraries.set(id, library);
              library.onChange.add(LimeAssets.onChange.dispatch);
              promise.completeWith(Future.withValue(library));
            }
          }).onError(function(_) {
            promise.error('There is no asset library with an ID of \'' + id + '\'');
        });
      
        return promise.future;
    }

    public static function transitionToState(state:NextState, stopMusic:Bool = false):Void
    {
        FlxG.switchState(() -> new LoadingSubState(state, stopMusic));
    }
}

class MultiCallback
{
  public var callback:Void->Void;
  public var logId:String = null;
  public var length(default, null) = 0;
  public var numRemaining(default, null) = 0;

  var unfired = new Map<String, Void->Void>();
  var fired = new Array<String>();

  public function new(callback:Void->Void, logId:String = null)
  {
    this.callback = callback;
    this.logId = logId;
  }

  public function add(id = 'untitled'):Void->Void
  {
    id = '$length:$id';
    length++;
    numRemaining++;
    var func:Void->Void = null;
    func = function() {
      if (unfired.exists(id))
      {
        unfired.remove(id);
        fired.push(id);
        numRemaining--;

        if (logId != null) log('fired $id, $numRemaining remaining');

        if (numRemaining == 0)
        {
          if (logId != null) log('all callbacks fired');
          callback();
        }
      }
      else
        log('already fired $id');
    }
    unfired[id] = func;
    return func;
  }

  inline function log(msg):Void
  {
    if (logId != null) trace('$logId: $msg');
  }

  public function getFired():Array<String>
    return fired.copy();

  public function getUnfired():Array<Void->Void>
    return unfired.array();
}