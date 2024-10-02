package graphics;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxTween;
import openfl.display3D.textures.TextureBase;
import graphics.framebuffer.FixedBitmapData;
import openfl.display.BitmapData;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame;
import flixel.FlxCamera;

class FunkinSprite extends FlxSprite
{
 /**
   * An internal list of all the textures cached with `cacheTexture`.
   * This excludes any temporary textures like those from `FlxText` or `makeSolidColor`.
   */
   static var currentCachedTextures:Map<String, FlxGraphic> = [];

   /**
    * An internal list of textures that were cached in the previous state.
    * We don't know whether we want to keep them cached or not.
    */
   static var previousCachedTextures:Map<String, FlxGraphic> = [];

    /**
   * @param x Starting X position
   * @param y Starting Y position
   */
    public function new(?x:Float = 0, ?y:Float = 0)
    {
      super(x, y);
    }

    public function loadImage(key:String)
    {
        var graphicKey:String = Paths.image(key);
        if (!isTextureCached(graphicKey)) FlxG.log.warn('Texture not cached, may experience stuttering! $graphicKey');
    
        this.loadGraphic(graphicKey);

        return this;

    }

    public function loadFrame(key:String)
    {
        var graphicKey:String = Paths.image(key);
        if (!isTextureCached(graphicKey)) FlxG.log.warn('Texture not cached, may experience stuttering! $graphicKey');
    
        this.frames = Paths.getAtlas(key);
        return this;
    }

    public static function isTextureCached(key:String):Bool
    {
        return FlxG.bitmap.get(key) != null;
    }

    public static function cacheTexture(key:String):Void
    {
        if (currentCachedTextures.exists(key)) return;

        if (previousCachedTextures.exists(key))
        {
          // Move the graphic from the previous cache to the current cache.
          var graphic = previousCachedTextures.get(key);
          previousCachedTextures.remove(key);
          currentCachedTextures.set(key, graphic);
          return;
        }

        var graphic:FlxGraphic = FlxGraphic.fromAssetKey(key, false, null, true);
        if (graphic == null)
        {
          FlxG.log.warn('Failed to cache graphic: $key');
        }
        else
        {
          trace('Successfully cached graphic: $key');
          graphic.persist = true;
          currentCachedTextures.set(key, graphic);
        }
    }

    public static function preparePurgeCache():Void
    {
        previousCachedTextures = currentCachedTextures;
        currentCachedTextures = [];
    }

    public static function purgeCache():Void
    {
        for (graphicKey in previousCachedTextures.keys())
        {
            var graphic = previousCachedTextures.get(graphicKey);
            if (graphic == null) continue;
            FlxG.bitmap.remove(graphic);
            graphic.destroy();
            previousCachedTextures.remove(graphicKey);
        }
    }

    static function isGraphicCached(graphic:FlxGraphic):Bool
    {
        if (graphic == null) return false;
        var result = FlxG.bitmap.get(graphic.key);
        if (result == null) return false;
        if (result != graphic)
        {
          FlxG.log.warn('Cached graphic does not match original: ${graphic.key}');
          return false;
        }
        return true;
    }

    public function makeSolidColor(width:Int, height:Int, color:FlxColor = FlxColor.WHITE):FunkinSprite
    {
        var graphic:FlxGraphic = FlxG.bitmap.create(2, 2, color, false, 'solid#${color.toHexString(true, false)}');
        frames = graphic.imageFrame;
        scale.set(width / 2.0, height / 2.0);
        updateHitbox();
    
        return this;
    }

    public override function clone():FunkinSprite
    {
        var result = new FunkinSprite(this.x, this.y);
        result.frames = this.frames;
        result.scale.set(this.scale.x, this.scale.y);
        result.updateHitbox();
    
        return result;
    }

    @:access(flixel.FlxCamera)
    override function getBoundingBox(camera:FlxCamera):FlxRect
    {
      getScreenPosition(_point, camera);
  
      _rect.set(_point.x, _point.y, width, height);
      _rect = camera.transformRect(_rect);
  
      if (isPixelPerfectRender(camera))
      {
        _rect.width = _rect.width / this.scale.x;
        _rect.height = _rect.height / this.scale.y;
        _rect.x = _rect.x / this.scale.x;
        _rect.y = _rect.y / this.scale.y;
        _rect.floor();
        _rect.x = _rect.x * this.scale.x;
        _rect.y = _rect.y * this.scale.y;
        _rect.width = _rect.width * this.scale.x;
        _rect.height = _rect.height * this.scale.y;
      }
  
      return _rect;
    }
  
    /**
     * Returns the screen position of this object.
     *
     * @param   result  Optional arg for the returning point
     * @param   camera  The desired "screen" coordinate space. If `null`, `FlxG.camera` is used.
     * @return  The screen position of this object.
     */
    public override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
    {
      if (result == null) result = FlxPoint.get();
  
      if (camera == null) camera = FlxG.camera;
  
      result.set(x, y);
      if (pixelPerfectPosition)
      {
        _rect.width = _rect.width / this.scale.x;
        _rect.height = _rect.height / this.scale.y;
        _rect.x = _rect.x / this.scale.x;
        _rect.y = _rect.y / this.scale.y;
        _rect.round();
        _rect.x = _rect.x * this.scale.x;
        _rect.y = _rect.y * this.scale.y;
        _rect.width = _rect.width * this.scale.x;
        _rect.height = _rect.height * this.scale.y;
      }
  
      return result.subtract(camera.scroll.x * scrollFactor.x, camera.scroll.y * scrollFactor.y);
    }
  
    override function drawSimple(camera:FlxCamera):Void
    {
      getScreenPosition(_point, camera).subtractPoint(offset);
      if (isPixelPerfectRender(camera))
      {
        _point.x = _point.x / this.scale.x;
        _point.y = _point.y / this.scale.y;
        _point.round();
  
        _point.x = _point.x * this.scale.x;
        _point.y = _point.y * this.scale.y;
      }
  
      _point.copyToFlash(_flashPoint);
      camera.copyPixels(_frame, framePixels, _flashRect, _flashPoint, colorTransform, blend, antialiasing);
    }
  
    override function drawComplex(camera:FlxCamera):Void
    {
      _frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
      _matrix.translate(-origin.x, -origin.y);
      _matrix.scale(scale.x, scale.y);
  
      if (bakedRotationAngle <= 0)
      {
        updateTrig();
  
        if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
      }
  
      getScreenPosition(_point, camera).subtractPoint(offset);
      _point.add(origin.x, origin.y);
      _matrix.translate(_point.x, _point.y);
  
      if (isPixelPerfectRender(camera))
      {
        _matrix.tx = Math.round(_matrix.tx / this.scale.x) * this.scale.x;
        _matrix.ty = Math.round(_matrix.ty / this.scale.y) * this.scale.y;
      }
  
      camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
    }
  
    public override function destroy():Void
    {
      frames = null;
      // Cancel all tweens so they don't continue to run on a destroyed sprite.
      // This prevents crashes.
      FlxTween.cancelTweensOf(this);
      super.destroy();
    }
}