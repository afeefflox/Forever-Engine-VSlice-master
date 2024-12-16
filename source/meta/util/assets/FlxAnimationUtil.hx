package meta.util.assets;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import data.AnimationData;

class FlxAnimationUtil
{
  /**
   * Properly adds an animation to a sprite based on the provided animation data.
   */
  public static function addAtlasAnimation(target:FlxSprite, anim:AnimationData)
  {
    var frameRate = anim.frameRate == null ? 24 : anim.frameRate;
    var looped = anim.looped == null ? false : anim.looped;

    if (anim.frameIndices != null && anim.frameIndices.length > 0)
      target.animation.addByIndices(anim.name, anim.prefix, anim.frameIndices, '', frameRate, looped);
    else
      target.animation.addByPrefix(anim.name, anim.prefix, frameRate, looped);
  }

  /**
  * Basically Animate Atlas support with labels and Symbol instead of only labels :/
  **/
  public static function addAnimateAtlasAnimation(target:FlxAnimate, anim:AnimationData)
  {
    var frameRate = anim.frameRate == null ? 24 : anim.frameRate;
    var looped = anim.looped == null ? false : anim.looped;


    if(target.anim.symbolDictionary.exists(anim.name)) //if Symbol exist :/
    {
      if (anim.frameIndices != null && anim.frameIndices.length > 0)
        target.anim.addBySymbolIndices(anim.name, anim.prefix, anim.frameIndices, frameRate);
      else
        target.anim.addBySymbol(anim.name, anim.prefix, frameRate);
    }
  }

  /**
   * Properly adds multiple animations to a sprite based on the provided animation data.
   */
  public static function addAtlasAnimations(target:FlxSprite, animations:Array<AnimationData>)
  {
    for (anim in animations)
    {
      addAtlasAnimation(target, anim);
    }
  }

  public static function addAnimateAtlasAnimations(target:FlxAnimate, animations:Array<AnimationData>)
  {
    for (anim in animations)
    {
      addAnimateAtlasAnimation(target, anim);
    }
  }

  public static function combineFramesCollections(a:FlxFramesCollection, b:FlxFramesCollection):FlxFramesCollection
  {
    var result:FlxFramesCollection = new FlxFramesCollection(null, ATLAS, null);

    for (frame in a.frames)
    {
      result.pushFrame(frame);
    }
    for (frame in b.frames)
    {
      result.pushFrame(frame);
    }

    return result;
  }
}
