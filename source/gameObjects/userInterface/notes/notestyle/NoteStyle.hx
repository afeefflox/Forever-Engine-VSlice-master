package gameObjects.userInterface.notes.notestyle;

import gameObjects.userInterface.Countdown;
import data.registry.base.IRegistryEntry;
import meta.util.assets.FlxAnimationUtil;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import gameObjects.userInterface.notes.EventSprite;
import meta.state.editors.content.NoteEditor;

using data.AnimationData.AnimationDataUtil;

class NoteStyle implements IRegistryEntry<NoteStyleData>
{
    public final id:String;
    public final _data:NoteStyleData;

    final fallback:Null<NoteStyle>;

    public function new(id:String)
    {
        this.id = id;
        _data = _fetchData(id);
    
        var fallbackID = _data.fallback;
        if (fallbackID != null) this.fallback = NoteStyleRegistry.instance.fetchEntry(fallbackID);
    }

    public function getName():String
        return _data.name;

    public function getAuthor():String
        return _data.author;

    public function getFallbackID():Null<String>
        return _data.fallback;

    public function buildEventSprite(target:EventSprite):Void
    {
      var atlas:Null<FlxAtlasFrames> = buildNoteFrames(false);

      if (atlas == null)
      {
        throw 'Could not load spritesheet for note style: $id';
      }
  
      target.frames = atlas;
      target.alpha = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;
      target.antialiasing = !(_data.assets?.note?.isPixel ?? false);
  
      // Apply the animations.
      buildNoteEventAnimations(target);
  
      // Set the scale.
      target.setGraphicSize(Strumline.STRUMLINE_SIZE * getNoteScale());
      target.updateHitbox();
    }

    public function buildNoteEditorSprite(target:NoteEditor):Void
    {
      var atlas:Null<FlxAtlasFrames> = buildNoteFrames(false);

      if (atlas == null)
      {
        throw 'Could not load spritesheet for note style: $id';
      }
      
      target.frames = atlas;
      target.alpha = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;
      target.antialiasing = !(_data.assets?.note?.isPixel ?? false);
      buildNoteAnimations(target);
    }

    public function buildNoteSprite(target:NoteSprite):Void
    {
        var atlas:Null<FlxAtlasFrames> = buildNoteFrames(false);

        if (atlas == null)
        {
          throw 'Could not load spritesheet for note style: $id';
        }
    
        target.frames = atlas;
        target.alpha = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;
        target.antialiasing = !(_data.assets?.note?.isPixel ?? false);
    
        // Apply the animations.
        buildNoteAnimations(target);
    
        // Set the scale.
        target.setGraphicSize(Strumline.STRUMLINE_SIZE * getNoteScale());
        target.updateHitbox();
    }

    var noteFrames:Null<FlxAtlasFrames> = null;

    function buildNoteFrames(force:Bool = false):Null<FlxAtlasFrames>
    {
        var noteAssetPath = getNoteAssetPath();
        if (noteAssetPath == null) return null;
    
        if (!FunkinSprite.isTextureCached(Paths.image(noteAssetPath)))
        {
          FlxG.log.warn('Note texture is not cached: ${noteAssetPath}');
        }
    
        // Purge the note frames if the cached atlas is invalid.
        if (noteFrames?.parent?.isDestroyed ?? false) noteFrames = null;
        if (noteFrames != null && !force) return noteFrames;
    
        var noteAssetPath = getNoteAssetPath();
        if (noteAssetPath == null) return null;
    
        noteFrames = Paths.getSparrowAtlas(noteAssetPath, getNoteAssetLibrary());
    
        if (noteFrames == null)
        {
          throw 'Could not load note frames for note style: $id';
        }
    
        return noteFrames;
    }

    function getNoteAssetPath(raw:Bool = false):Null<String>
    {
        if (raw)
        {
            var rawPath:Null<String> = _data?.assets?.note?.assetPath;
            if (rawPath == null && fallback != null) return fallback.getNoteAssetPath(true);
            return rawPath;
        }
        
        // library:path
        var parts = getNoteAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
        if (parts.length == 0) return null;
        if (parts.length == 1) return getNoteAssetPath(true);
        return parts[1];
    }

    function getNoteAssetLibrary():Null<String>
    {
        var parts = getNoteAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
        if (parts.length == 0) return null;
        if (parts.length == 1) return null;
        return parts[0];        
    }

    function buildNoteAnimations(target:FlxSprite):Void
    {
        var leftData:Null<AnimationData> = fetchNoteAnimationData(LEFT);
        if (leftData != null) target.animation.addByPrefix('purpleScroll', leftData.prefix ?? '', leftData.frameRate ?? 24, leftData.looped ?? false);
        var downData:Null<AnimationData> = fetchNoteAnimationData(DOWN);
        if (downData != null) target.animation.addByPrefix('blueScroll', downData.prefix ?? '', downData.frameRate ?? 24, downData.looped ?? false);
        var upData:Null<AnimationData> = fetchNoteAnimationData(UP);
        if (upData != null) target.animation.addByPrefix('greenScroll', upData.prefix ?? '', upData.frameRate ?? 24, upData.looped ?? false);
        var rightData:Null<AnimationData> = fetchNoteAnimationData(RIGHT);
        if (rightData != null) target.animation.addByPrefix('redScroll', rightData.prefix ?? '', rightData.frameRate ?? 24, rightData.looped ?? false);
    }

    function buildNoteEventAnimations(target:EventSprite):Void
      {
          var leftData:Null<AnimationData> = fetchNoteAnimationData(LEFT);
          if (leftData != null) target.animation.addByPrefix('purpleScroll', leftData.prefix ?? '', leftData.frameRate ?? 24, leftData.looped ?? false);
          var downData:Null<AnimationData> = fetchNoteAnimationData(DOWN);
          if (downData != null) target.animation.addByPrefix('blueScroll', downData.prefix ?? '', downData.frameRate ?? 24, downData.looped ?? false);
          var upData:Null<AnimationData> = fetchNoteAnimationData(UP);
          if (upData != null) target.animation.addByPrefix('greenScroll', upData.prefix ?? '', upData.frameRate ?? 24, upData.looped ?? false);
          var rightData:Null<AnimationData> = fetchNoteAnimationData(RIGHT);
          if (rightData != null) target.animation.addByPrefix('redScroll', rightData.prefix ?? '', rightData.frameRate ?? 24, rightData.looped ?? false);
      }

    public function isNoteAnimated():Bool
        return _data.assets?.note?.animated ?? false;

    public function getNoteScale():Float
        return _data.assets?.note?.scale ?? 1.0;

    function fetchNoteAnimationData(dir:NoteDirection):Null<AnimationData>
    {
        var result:Null<AnimationData> = switch (dir)
        {
          case LEFT: _data.assets?.note?.data?.left?.toNamed();
          case DOWN: _data.assets?.note?.data?.down?.toNamed();
          case UP: _data.assets?.note?.data?.up?.toNamed();
          case RIGHT: _data.assets?.note?.data?.right?.toNamed();
        };
    
        return (result == null && fallback != null) ? fallback.fetchNoteAnimationData(dir) : result;
    }

    public function getHoldNoteAssetPath(raw:Bool = false):Null<String>
    {
        if (raw)
        {
            // TODO: figure out why ?. didn't work here
            var rawPath:Null<String> = (_data?.assets?.holdNote == null) ? null : _data?.assets?.holdNote?.assetPath;
            return (rawPath == null && fallback != null) ? fallback.getHoldNoteAssetPath(true) : rawPath;
        }
        
        // library:path
        var parts = getHoldNoteAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
        if (parts.length == 0) return null;
        if (parts.length == 1) return Paths.image(parts[0]);
        return Paths.image(parts[1], parts[0]);
    }

    public function isHoldNotePixel():Bool
    {
        var data = _data?.assets?.holdNote;
        if (data == null && fallback != null) return fallback.isHoldNotePixel();
        return data?.isPixel ?? false;
    }

    public function fetchHoldNoteScale():Float
    {
        var data = _data?.assets?.holdNote;
        if (data == null && fallback != null) return fallback.fetchHoldNoteScale();
        return data?.scale ?? 1.0;
    }

    public function applyStrumlineFrames(target:StrumlineNote):Void
    {
        var atlas:FlxAtlasFrames = Paths.getSparrowAtlas(getStrumlineAssetPath() ?? '', getStrumlineAssetLibrary());

        if (atlas == null)
        {
          throw 'Could not load spritesheet for note style: $id';
        }
    
        target.frames = atlas;
    
        target.scale.set(_data.assets.noteStrumline?.scale ?? 1.0);
        target.antialiasing = !(_data.assets.noteStrumline?.isPixel ?? false);
    }

    function getStrumlineAssetPath(raw:Bool = false):Null<String>
    {
        if (raw)
        {
            var rawPath:Null<String> = _data?.assets?.noteStrumline?.assetPath;
            if (rawPath == null && fallback != null) return fallback.getStrumlineAssetPath(true);
            return rawPath;
        }
        
        // library:path
        var parts = getStrumlineAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
        if (parts.length <= 1) return getStrumlineAssetPath(true);
        return parts[1];
    }

    function getStrumlineAssetLibrary():Null<String>
    {
        var parts = getStrumlineAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
        if (parts.length <= 1) return null;
        return parts[0];
    }

    public function applyStrumlineAnimations(target:StrumlineNote, dir:NoteDirection):Void
        FlxAnimationUtil.addAtlasAnimations(target, getStrumlineAnimationData(dir));

    function getStrumlineAnimationData(dir:NoteDirection):Array<AnimationData>
    {
        var result:Array<Null<AnimationData>> = switch (dir)
        {
          case NoteDirection.LEFT: [
              _data.assets.noteStrumline?.data?.leftStatic?.toNamed('static'),
              _data.assets.noteStrumline?.data?.leftPress?.toNamed('press'),
              _data.assets.noteStrumline?.data?.leftConfirm?.toNamed('confirm'),
              _data.assets.noteStrumline?.data?.leftConfirmHold?.toNamed('confirm-hold'),
            ];
          case NoteDirection.DOWN: [
              _data.assets.noteStrumline?.data?.downStatic?.toNamed('static'),
              _data.assets.noteStrumline?.data?.downPress?.toNamed('press'),
              _data.assets.noteStrumline?.data?.downConfirm?.toNamed('confirm'),
              _data.assets.noteStrumline?.data?.downConfirmHold?.toNamed('confirm-hold'),
            ];
          case NoteDirection.UP: [
              _data.assets.noteStrumline?.data?.upStatic?.toNamed('static'),
              _data.assets.noteStrumline?.data?.upPress?.toNamed('press'),
              _data.assets.noteStrumline?.data?.upConfirm?.toNamed('confirm'),
              _data.assets.noteStrumline?.data?.upConfirmHold?.toNamed('confirm-hold'),
            ];
          case NoteDirection.RIGHT: [
              _data.assets.noteStrumline?.data?.rightStatic?.toNamed('static'),
              _data.assets.noteStrumline?.data?.rightPress?.toNamed('press'),
              _data.assets.noteStrumline?.data?.rightConfirm?.toNamed('confirm'),
              _data.assets.noteStrumline?.data?.rightConfirmHold?.toNamed('confirm-hold'),
            ];
          default: [];
        };
    
        return thx.Arrays.filterNull(result);        
    }

    public function applyStrumlineOffsets(target:StrumlineNote):Void
    {
        var offsets = _data?.assets?.noteStrumline?.offsets ?? [0.0, 0.0];
        target.x += offsets[0];
        target.y += offsets[1];
    }

    public function getStrumlineScale():Float
    {
        return _data?.assets?.noteStrumline?.scale ?? 1.0;
    }

    public function isNoteSplashEnabled():Bool
    {
        var data = _data?.assets?.noteSplash?.data;
        if (data == null) return fallback?.isNoteSplashEnabled() ?? false;
        return data.enabled ?? false;    
    }

    public function isHoldNoteCoverEnabled():Bool
    {
        var data = _data?.assets?.holdNoteCover?.data;
        if (data == null) return fallback?.isHoldNoteCoverEnabled() ?? false;
        return data.enabled ?? false;
    }

    public function buildCountdownSprite(step:Countdown.CountdownStep):Null<FunkinSprite>
    {
        var result = new FunkinSprite();

        switch (step)
        {
            case THREE:
                if (_data.assets.countdownThree == null) return fallback?.buildCountdownSprite(step);
                var assetPath = buildCountdownSpritePath(step);
                if (assetPath == null) return null;
                result.loadImage(assetPath);
                result.scale.x = _data.assets.countdownThree?.scale ?? 1.0;
                result.scale.y = _data.assets.countdownThree?.scale ?? 1.0;
              case TWO:
                if (_data.assets.countdownTwo == null) return fallback?.buildCountdownSprite(step);
                var assetPath = buildCountdownSpritePath(step);
                if (assetPath == null) return null;
                result.loadImage(assetPath);
                result.scale.x = _data.assets.countdownTwo?.scale ?? 1.0;
                result.scale.y = _data.assets.countdownTwo?.scale ?? 1.0;
              case ONE:
                if (_data.assets.countdownOne == null) return fallback?.buildCountdownSprite(step);
                var assetPath = buildCountdownSpritePath(step);
                if (assetPath == null) return null;
                result.loadImage(assetPath);
                result.scale.x = _data.assets.countdownOne?.scale ?? 1.0;
                result.scale.y = _data.assets.countdownOne?.scale ?? 1.0;
              case GO:
                if (_data.assets.countdownGo == null) return fallback?.buildCountdownSprite(step);
                var assetPath = buildCountdownSpritePath(step);
                if (assetPath == null) return null;
                result.loadImage(assetPath);
                result.scale.x = _data.assets.countdownGo?.scale ?? 1.0;
                result.scale.y = _data.assets.countdownGo?.scale ?? 1.0;
              default:
                // TODO: Do something here?
                return null;            
        }
        result.scrollFactor.set(0, 0);
        result.antialiasing = !isCountdownSpritePixel(step);
        result.updateHitbox();
    
        return result;        
    }

    function buildCountdownSpritePath(step:Countdown.CountdownStep):Null<String>
    {
        var basePath:Null<String> = null;
        switch (step)
        {
          case THREE:
            basePath = _data.assets.countdownThree?.assetPath;
          case TWO:
            basePath = _data.assets.countdownTwo?.assetPath;
          case ONE:
            basePath = _data.assets.countdownOne?.assetPath;
          case GO:
            basePath = _data.assets.countdownGo?.assetPath;
          default:
            basePath = null;
        }
    
        if (basePath == null) return fallback?.buildCountdownSpritePath(step);
    
        var parts = basePath?.split(Constants.LIBRARY_SEPARATOR) ?? [];
        if (parts.length < 1) return null;
        if (parts.length == 1) return parts[0];
    
        return parts[1];
      }
    
      function buildCountdownSpriteLibrary(step:Countdown.CountdownStep):Null<String>
      {
        var basePath:Null<String> = null;
        switch (step)
        {
          case THREE:
            basePath = _data.assets.countdownThree?.assetPath;
          case TWO:
            basePath = _data.assets.countdownTwo?.assetPath;
          case ONE:
            basePath = _data.assets.countdownOne?.assetPath;
          case GO:
            basePath = _data.assets.countdownGo?.assetPath;
          default:
            basePath = null;
        }
    
        if (basePath == null) return fallback?.buildCountdownSpriteLibrary(step);
    
        var parts = basePath?.split(Constants.LIBRARY_SEPARATOR) ?? [];
        if (parts.length <= 1) return null;
    
        return parts[0];
    }

    public function isCountdownSpritePixel(step:Countdown.CountdownStep):Bool
    {
        switch (step)
        {
          case THREE:
            var result = _data.assets.countdownThree?.isPixel;
            if (result == null && fallback != null) result = fallback.isCountdownSpritePixel(step);
            return result ?? false;
          case TWO:
            var result = _data.assets.countdownTwo?.isPixel;
            if (result == null && fallback != null) result = fallback.isCountdownSpritePixel(step);
            return result ?? false;
          case ONE:
            var result = _data.assets.countdownOne?.isPixel;
            if (result == null && fallback != null) result = fallback.isCountdownSpritePixel(step);
            return result ?? false;
          case GO:
            var result = _data.assets.countdownGo?.isPixel;
            if (result == null && fallback != null) result = fallback.isCountdownSpritePixel(step);
            return result ?? false;
          default:
            return false;
        }
    }

    public function getCountdownSpriteOffsets(step:Countdown.CountdownStep):Array<Float>
      {
        switch (step)
        {
          case THREE:
            var result = _data.assets.countdownThree?.offsets;
            if (result == null && fallback != null) result = fallback.getCountdownSpriteOffsets(step);
            return result ?? [0, 0];
          case TWO:
            var result = _data.assets.countdownTwo?.offsets;
            if (result == null && fallback != null) result = fallback.getCountdownSpriteOffsets(step);
            return result ?? [0, 0];
          case ONE:
            var result = _data.assets.countdownOne?.offsets;
            if (result == null && fallback != null) result = fallback.getCountdownSpriteOffsets(step);
            return result ?? [0, 0];
          case GO:
            var result = _data.assets.countdownGo?.offsets;
            if (result == null && fallback != null) result = fallback.getCountdownSpriteOffsets(step);
            return result ?? [0, 0];
          default:
            return [0, 0];
        }
      }
    public function getCountdownSoundPath(step:Countdown.CountdownStep, raw:Bool = false):Null<String>
    {
        if (raw)
        {
            // TODO: figure out why ?. didn't work here
            var rawPath:Null<String> = switch (step)
            {
              case Countdown.CountdownStep.THREE:
                _data.assets.countdownThree?.data?.audioPath;
              case Countdown.CountdownStep.TWO:
                _data.assets.countdownTwo?.data?.audioPath;
              case Countdown.CountdownStep.ONE:
                _data.assets.countdownOne?.data?.audioPath;
              case Countdown.CountdownStep.GO:
                _data.assets.countdownGo?.data?.audioPath;
              default:
                null;
            }
      
            return (rawPath == null && fallback != null) ? fallback.getCountdownSoundPath(step, true) : rawPath;
        }
      
          // library:path
        var parts = getCountdownSoundPath(step, true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
        if (parts.length == 0) return null;
        if (parts.length == 1) return Paths.image(parts[0]);
        return Paths.sound(parts[1], parts[0]);
    }

    public function buildJudgementSprite():Null<FunkinSprite>
    {
        var result = new FunkinSprite();

        if (_data.assets.judgement == null) return fallback?.buildJudgementSprite();
        var assetPath = buildJudgementSpritePath();
        if (assetPath == null) return null;
        result.loadGraphic(Paths.image(assetPath), true, _data.assets.judgement.data.width, _data.assets.judgement.data.height);       
        result.scale.x = _data.assets.judgement?.scale ?? 1.0;
        result.scale.y = _data.assets.judgement?.scale ?? 1.0;
        var isPixel = isJudgementSpritePixel();
        result.antialiasing = !isPixel;
        result.pixelPerfectRender = isPixel;
        result.pixelPerfectPosition = isPixel;
        result.updateHitbox();

        var offsets = getJudgementSpriteOffsets();
        result.x += offsets[0];
        result.y += offsets[1];
    
        return result;
    }

    public function isJudgementSpritePixel():Bool
    {
      var result = _data.assets.judgement?.isPixel;
      if (result == null && fallback != null) result = fallback.isJudgementSpritePixel();
      return result ?? false;
    }

    function buildJudgementSpritePath():Null<String>
    {
        var basePath:Null<String> = _data.assets.judgement?.assetPath;
        if (basePath == null) return fallback?.buildJudgementSpritePath();

        var parts = basePath?.split(Constants.LIBRARY_SEPARATOR) ?? [];
        if (parts.length < 1) return null;
        if (parts.length == 1) return parts[0];
    
        return parts[1];
    }

    public function getJudgementSpriteOffsets():Array<Float>
    {
      var result = _data.assets.judgement?.offsets;
      if (result == null && fallback != null) result = fallback.getJudgementSpriteOffsets();
      return result ?? [0, 0];
    }
     
    
    public function buildComboNumSprite():Null<FunkinSprite>
    {
        var result = new FunkinSprite();

        if (_data.assets.combo == null) return fallback?.buildComboNumSprite();
        var assetPath = buildComboNumSpritePath();
        if (assetPath == null) return null;

        result.loadGraphic(Paths.image(assetPath), true, _data.assets.combo.data.width, _data.assets.combo.data.height);       
        result.scale.x = _data.assets.combo?.scale ?? 1.0;
        result.scale.y = _data.assets.combo?.scale ?? 1.0;
    
        var isPixel = isComboNumSpritePixel();
        result.antialiasing = !isPixel;
        result.pixelPerfectRender = isPixel;
        result.pixelPerfectPosition = isPixel;
        result.updateHitbox();

        var offsets = getComboNumSpriteOffsets();
        result.x += offsets[0];
        result.y += offsets[1];
    
        return result;        
    }

  public function isComboNumSpritePixel():Bool
  {
    var result = _data.assets.combo?.isPixel;
    if (result == null && fallback != null) result = fallback.isComboNumSpritePixel();
    return result ?? false;
  }

  function buildComboNumSpritePath():Null<String>
  {
    var basePath:Null<String> = _data.assets.combo?.assetPath;
    if (basePath == null) return fallback?.buildComboNumSpritePath();

    var parts = basePath?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length < 1) return null;
    if (parts.length == 1) return parts[0];

    return parts[1];
  }

  public function getComboNumSpriteOffsets():Array<Float>
  {
    var result = _data.assets.combo?.offsets;
    if (result == null && fallback != null) result = fallback.getComboNumSpriteOffsets();
    return result ?? [0, 0];
  }

  public function destroy():Void {}

  public function toString():String
  {
    return 'NoteStyle($id)';
  }

  static function _fetchData(id:String):NoteStyleData
  {
    var result = NoteStyleRegistry.instance.parseEntryDataWithMigration(id, NoteStyleRegistry.instance.fetchEntryVersion(id));

    if (result == null)
    {
      throw 'Could not parse note style data for id: $id';
    }
    else
    {
      return result;
    }
  }
    
}