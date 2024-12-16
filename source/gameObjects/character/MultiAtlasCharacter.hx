package gameObjects.character;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import meta.modding.events.ScriptEvent;
import meta.util.assets.FlxAnimationUtil;
import data.CharacterData.CharacterRenderType;

class MultiAtlasCharacter extends BaseCharacter
{
    public function new(id:String)
    {
        super(id, CharacterRenderType.MultiAtlas);
    }

    override function onCreate(event:ScriptEvent):Void
    {
        trace('Creating atlas character: ' + this.id);
      
        loadSpritesheet();
        loadAnimations();
      
        super.onCreate(event);
    }

    function loadSpritesheet()
    {
      var assetList = [];
      for (anim in _data.animations)
      {
        if (anim.assetPath != null && anim.assetPath != "" && !assetList.contains(anim.assetPath))
        {
          assetList.push(anim.assetPath);
        }
      }
    
      var texture:FlxAtlasFrames = Paths.getAtlas(_data.assetPath);
    
        if (texture == null)
        {
          trace('Multi-atlas atlas could not load PRIMARY texture: ${_data.assetPath}');
        }
        else
        {
          trace('Creating multi-atlas atlas: ${_data.assetPath}');
          texture.parent.destroyOnNoUse = false;
        }
    
        for (asset in assetList)
        {
          var subTexture:FlxAtlasFrames = Paths.getAtlas(asset);
          // If we don't do this, the unused textures will be removed as soon as they're loaded.
    
          if (subTexture == null)
          {
            trace('Multi-atlas atlas could not load subtexture: ${asset}');
          }
          else
          {
            trace('Concatenating multi-atlas atlas: ${asset}');
            subTexture.parent.destroyOnNoUse = false;
          }
    
          texture.addAtlas(subTexture);
        }
          
        this.frames = texture;
        this.antialiasing = _data.antialiasing;
        this.setScale(_data.scale);        
    }

    function loadAnimations()
    {
        trace('[MULTIATLASCHAR] Loading ${_data.animations.length} animations for ${id}');

        FlxAnimationUtil.addAtlasAnimations(this, _data.animations);
    
        for (anim in _data.animations)
        {
          if (anim.offsets == null)
            setAnimationOffsets(anim.name, 0, 0);
          else
            setAnimationOffsets(anim.name, anim.offsets[0], anim.offsets[1]);
        }
    
        var animNames = this.animation.getNameList();
        trace('[MULTIATLASCHAR] Successfully loaded ${animNames.length} animations for ${id}');
    }
}