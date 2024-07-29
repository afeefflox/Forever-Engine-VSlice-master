package gameObjects.character;

import meta.modding.events.ScriptEvent;
import meta.util.assets.FlxAnimationUtil;
import flixel.graphics.frames.FlxFramesCollection;
import data.CharacterData.CharacterRenderType;

class AtlasCharacter extends BaseCharacter
{
  public function new(id:String)
  {
    super(id, CharacterRenderType.Atlas);
  }

  override function onCreate(event:ScriptEvent):Void
  {
    trace('Creating Sparrow character: ' + this.id);

    loadSpritesheet();
    loadAnimations();

    super.onCreate(event);
  }

  function loadSpritesheet()
  {
    trace('[ATLASCHAR] Loading spritesheet ${_data.assetPath} for ${id}');

    var tex:FlxFramesCollection = Paths.getAtlas(_data.assetPath);
    if (tex == null)
    {
      trace('Could not load Sparrow sprite: ${_data.assetPath}');
      return;
    }

    this.frames = tex;
    this.antialiasing = _data.antialiasing;
    this.setScale(_data.scale);
  }

  function loadAnimations()
  {
    trace('[ATLASCHAR] Loading ${_data.animations.length} animations for ${id}');

    FlxAnimationUtil.addAtlasAnimations(this, _data.animations);

    for (anim in _data.animations)
    {
      if (anim.offsets == null)
        setAnimationOffsets(anim.name, 0, 0);
      else
        setAnimationOffsets(anim.name, anim.offsets[0], anim.offsets[1]);
    }

    var animNames = this.animation.getNameList();
    trace('[ATLASCHAR] Successfully loaded ${animNames.length} animations for ${id}');
  }
}
