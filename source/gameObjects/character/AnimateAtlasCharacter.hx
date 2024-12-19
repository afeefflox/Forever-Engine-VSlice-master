package gameObjects.character;

import data.CharacterData.CharacterRenderType;
import meta.modding.events.ScriptEvent;


import flixel.util.FlxDestroyUtil;
import flixel.animation.FlxAnimationController;
import flixel.math.FlxPoint;
import flixel.math.FlxPoint.FlxCallbackPoint;
import openfl.display.BlendMode;
import flixel.FlxCamera;
import flixel.math.FlxRect;
import flixel.math.FlxMath;

class AnimateAtlasCharacter extends BaseCharacter 
{
    public var mainSprite:FlxAtlasSprite;

    var animations:Map<String, AnimationData> = new Map<String, AnimationData>();
    var currentAnimName:Null<String> = null;
    var animFinished:Bool = false;

    public function new(id:String)
    {
        super(id, CharacterRenderType.AnimateAtlas);
    }

    override function onCreate(event:ScriptEvent)
    {
        trace('Creating Animate Atlas character: ' + this.id);

        loadAnimateAtlas();
        loadAnimations();
    }

    function loadAnimateAtlas()
    {
        trace('[ATLASANIMATECHAR] Loading Animate Atlas ${_data.assetPath} for ${id}');
        var atlasSprite:FlxAtlasSprite = loadAtlasSprite();
        setSprite(atlasSprite);
    }

    function loadAtlasSprite():FlxAtlasSprite
    {
        var sprite:FlxAtlasSprite = new FlxAtlasSprite(0, 0, Paths.animateAtlas(_data.assetPath));
        sprite.onAnimationComplete.add(this.onAnimationFinished);
        return sprite;
    }

    function loadAnimations()
    {
        trace('[ATLASANIMATECHAR] Loading ${_data.animations.length} animations for ${id}');
        for (anim in _data.animations) addAnimation(anim);
        trace('[ATLASANIMATECHAR] Loaded ${animations.size()} animations for ${id}');        
    }

    public function addAnimation(anim:AnimationData)
    {
        var prefix = anim.prefix;
        if (!this.mainSprite.hasAnimation(prefix))
        {
            FlxG.log.warn('[ATLASANIMATECHAR] Animation ${prefix} not found in Animate Atlas ${_data.assetPath}');
            trace('[ATLASANIMATECHAR] Animation ${prefix} not found in Animate Atlas ${_data.assetPath}');
            return;
        }
        animations.set(anim.name, anim);
        trace('[ATLASANIMATECHAR] - Successfully loaded animation ${anim.name} to ${id}');
    }

    public override function playAnim(name:String, restart:Bool = false, ignoreOther:Bool = false, reverse:Bool = false):Void
    {
        if (!canPlayOtherAnims && !ignoreOther) return;

        var correctName = correctAnimationName(name);
        if (correctName == null) return;

        var animData = getAnimationData(correctName);
        currentAnimName = correctName;
        var prefix:String = animData.prefix;
        if (prefix == null) prefix = correctName;
        var loop:Bool = animData.looped;

        this.mainSprite.playAnimation(prefix, restart, ignoreOther, loop);
    }

    public override function hasAnimation(name:String):Bool
        return getAnimationData(name) != null;

    public override function isAnimationFinished():Bool
        return mainSprite?.isAnimationFinished() ?? false;

    override function get_animPaused():Bool
        return this.mainSprite.anim.isPlaying;

    override function set_animPaused(value:Bool):Bool
    {
        if(value) this.mainSprite.anim.pause();
        else this.mainSprite.anim.resume();
        return value;        
    }

    override function getCurrentAnimation():String
        return currentAnimName;

    function getAnimationData(name:String = null):AnimationData
    {
        if (name == null) name = getCurrentAnimation();
        return animations.get(name);
    }

    override function finishAnimation()
        this.mainSprite.anim.curFrame = this.mainSprite.anim.length - 1;

    override function isAnimationNull():Bool
    {
        return (this.mainSprite.anim == null || this.mainSprite.anim.curSymbol == null);
    }

    override function switchAnim(anim1:String, anim2:String):Void
    {
        if (hasAnimation(anim1) && hasAnimation(anim2))
        {
            final oldAnim1 = this.mainSprite.anim.getByName(anim1).instance.symbol;
            final oldOffset1 = animOffsets[anim1];
        
            this.mainSprite.anim.getByName(anim1).instance.symbol = this.mainSprite.anim.getByName(anim2).instance.symbol;
            animOffsets[anim1] = animOffsets[anim2];
            this.mainSprite.anim.getByName(anim2).instance.symbol = oldAnim1;
            animOffsets[anim2] = oldOffset1;
        }
    }

    override function onAnimationFinished(prefix:String):Void
    {
        super.onAnimationFinished(prefix);

        if (getAnimationData() != null && getAnimationData().looped)
            playAnim(currentAnimName, true, false);
        else
            this.mainSprite.cleanupAnimation(prefix);
    }

    function setSprite(sprite:FlxAtlasSprite):Void
    {
        this.mainSprite = sprite;
        this.mainSprite.alpha = 0.0001;
        this.mainSprite.draw();
        this.mainSprite.alpha = 1.0;
        this.mainSprite.antialiasing = _data.antialiasing;

        sprite.x = this.x;
        sprite.y = this.y;
        sprite.alpha *= alpha;
        sprite.flipX = flipX;
        sprite.flipY = flipY;
        sprite.scrollFactor.copyFrom(scrollFactor);
        sprite.cameras = _cameras; // _cameras instead of cameras because get_cameras() will not return null
    
        if (clipRect != null) clipRectTransform(sprite, clipRect);
    }

    override function initVars():Void
    {
        animation = new FlxAnimationController(this);

        offset = new FlxCallbackPoint(offsetCallback);
        origin = new FlxCallbackPoint(originCallback);
        scale = new FlxCallbackPoint(scaleCallback);
        scrollFactor = new FlxCallbackPoint(scrollFactorCallback);
    
        scale.set(1, 1);
        scrollFactor.set(1, 1);
    
        initMotionVars();
    }

    var _skipTransformChildren:Bool = false;

    @:generic
    public function transformChildren<V>(callback:FlxAnimate->V->Void, value:V):Void
    {
        if (_skipTransformChildren || this.mainSprite == null) return;

        callback(this.mainSprite, value);
    }

    public override function kill():Void
    {
        _skipTransformChildren = true;
        super.kill();
        _skipTransformChildren = false;

        if (this.mainSprite != null)
        {
            this.mainSprite.kill();
            this.mainSprite = null;
        }
    }

    public override function revive():Void
    {
        _skipTransformChildren = true;
        super.revive(); // calls set_exists and set_alive
        _skipTransformChildren = false;
        this.mainSprite.revive();
    }

    public override function destroy():Void
    {
        offset = FlxDestroyUtil.destroy(offset);
        origin = FlxDestroyUtil.destroy(origin);
        scale = FlxDestroyUtil.destroy(scale);
        scrollFactor = FlxDestroyUtil.destroy(scrollFactor);
    
        this.mainSprite = FlxDestroyUtil.destroy(this.mainSprite);
    
        super.destroy();
    }

    public override function isOnScreen(?camera:FlxCamera):Bool
    {
        if (this.mainSprite != null && this.mainSprite.exists && this.mainSprite.visible && this.mainSprite.isOnScreen(camera)) return true;
        return false;
    }

    public override function overlapsPoint(point:FlxPoint, inScreenSpace:Bool = false, camera:FlxCamera = null):Bool
    {
        var result:Bool = false;
        result = this.mainSprite.overlapsPoint(point, inScreenSpace, camera);
        return result;
    }

    public override function pixelsOverlapPoint(point:FlxPoint, Mask:Int = 0xFF, Camera:FlxCamera = null):Bool
    {
        var result:Bool = false;
        if (this.mainSprite != null && this.mainSprite.exists && this.mainSprite.visible)
            result = this.mainSprite.pixelsOverlapPoint(point, Mask, Camera);
        return result;
    }

    public override function update(elapsed:Float):Void
    {
        this.mainSprite.update(elapsed);

        if (moves) updateMotion(elapsed);
    }

    public override function draw():Void
        this.mainSprite.draw();

    inline function xTransform(sprite:FlxSprite, x:Float):Void
        sprite.x += x; // addition
    
    inline function yTransform(sprite:FlxSprite, y:Float):Void
        sprite.y += y; // addition
    
    inline function angleTransform(sprite:FlxSprite, angle:Float):Void
        sprite.angle += angle; // addition

    inline function alphaTransform(sprite:FlxSprite, alpha:Float):Void
    {
        if (sprite.alpha != 0 || alpha == 0)
            sprite.alpha *= alpha; // multiplication
        else
            sprite.alpha = 1 / alpha; // direct set to avoid stuck sprites
    }

    inline function directAlphaTransform(sprite:FlxSprite, alpha:Float):Void
        sprite.alpha = alpha; // direct set

    inline function facingTransform(sprite:FlxSprite, facing:Int):Void
        sprite.facing = facing;
    
    inline function flipXTransform(sprite:FlxSprite, flipX:Bool):Void
        sprite.flipX = flipX;
    
    inline function flipYTransform(sprite:FlxSprite, flipY:Bool):Void
        sprite.flipY = flipY;
    
    inline function movesTransform(sprite:FlxSprite, moves:Bool):Void
        sprite.moves = moves;
    
    inline function pixelPerfectTransform(sprite:FlxSprite, pixelPerfect:Bool):Void
        sprite.pixelPerfectRender = pixelPerfect;
    
    inline function gColorTransform(sprite:FlxSprite, color:Int):Void
        sprite.color = color;
    
    inline function blendTransform(sprite:FlxSprite, blend:BlendMode):Void
        sprite.blend = blend;
    
    inline function immovableTransform(sprite:FlxSprite, immovable:Bool):Void
        sprite.immovable = immovable;
    
    inline function visibleTransform(sprite:FlxSprite, visible:Bool):Void
        sprite.visible = visible;
    
    inline function activeTransform(sprite:FlxSprite, active:Bool):Void
      sprite.active = active;
    
    inline function solidTransform(sprite:FlxSprite, solid:Bool):Void
        sprite.solid = solid;
    
    inline function aliveTransform(sprite:FlxSprite, alive:Bool):Void
        sprite.alive = alive;
    
    inline function existsTransform(sprite:FlxSprite, exists:Bool):Void
        sprite.exists = exists;
    
    inline function cameraTransform(sprite:FlxSprite, camera:FlxCamera):Void
        sprite.camera = camera;
    
    inline function camerasTransform(sprite:FlxSprite, cameras:Array<FlxCamera>):Void
        sprite.cameras = cameras;
    
    inline function offsetTransform(sprite:FlxSprite, offset:FlxPoint):Void
        sprite.offset.copyFrom(offset);
    
    inline function originTransform(sprite:FlxSprite, origin:FlxPoint):Void
        sprite.origin.copyFrom(origin);
    
    inline function scaleTransform(sprite:FlxSprite, scale:FlxPoint):Void
        sprite.scale.copyFrom(scale);
    
    inline function scrollFactorTransform(sprite:FlxSprite, scrollFactor:FlxPoint):Void
        sprite.scrollFactor.copyFrom(scrollFactor);

    inline function clipRectTransform(sprite:FlxSprite, clipRect:FlxRect):Void
    {
        if (clipRect == null)
            sprite.clipRect = null;
        else
            sprite.clipRect = FlxRect.get(clipRect.x - sprite.x + x, clipRect.y - sprite.y + y, clipRect.width, clipRect.height);
    }

    inline function offsetCallback(offset:FlxPoint):Void
        transformChildren(offsetTransform, offset);
    
    inline function originCallback(origin:FlxPoint):Void
        transformChildren(originTransform, origin);
    
    inline function scaleCallback(scale:FlxPoint):Void
        transformChildren(scaleTransform, scale);
    
    inline function scrollFactorCallback(scrollFactor:FlxPoint):Void
        transformChildren(scrollFactorTransform, scrollFactor);

    override function set_camera(value:FlxCamera):FlxCamera
    {
        if (camera != value) transformChildren(cameraTransform, value);
        return super.set_camera(value);
    }

    override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera>
    {
        if (cameras != value) transformChildren(camerasTransform, value);
        return super.set_cameras(value);
    }

    override function set_exists(value:Bool):Bool
    {
        if (exists != value) transformChildren(existsTransform, value);
        return super.set_exists(value);
    }

    override function set_visible(value:Bool):Bool
    {
        if (exists && visible != value) transformChildren(visibleTransform, value);
        return super.set_visible(value);
    }

    override function set_active(value:Bool):Bool
    {
        if (exists && active != value) transformChildren(activeTransform, value);
        return super.set_active(value);
    }

    override function set_alive(value:Bool):Bool
    {
        if (alive != value) transformChildren(aliveTransform, value);
        return super.set_alive(value);
    }

    override function set_x(value:Float):Float
    {
        if (!exists || x == value) return x; // early return (no need to transform)

        transformChildren(xTransform, value - x); // offset
        return x = value;
    }

    override function set_y(value:Float):Float
    {
        if (exists && y != value) transformChildren(yTransform, value - y); // offset
        return y = value;
    }

    override function set_angle(value:Float):Float
    {
        if (exists && angle != value) transformChildren(angleTransform, value - angle); // offset
        return angle = value;
    }

    override function set_alpha(value:Float):Float
    {
        value = FlxMath.bound(value, 0, 1);

        if (exists && alpha != value)  transformChildren(directAlphaTransform, value);
        return alpha = value;
    }

    override function set_facing(value:Int):Int
    {
        if (exists && facing != value) transformChildren(facingTransform, value);
        return facing = value;
    }

    override function set_flipX(value:Bool):Bool
    {
        if (exists && flipX != value) transformChildren(flipXTransform, value);
        return flipX = value;
    }

    override function set_flipY(value:Bool):Bool
    {
        if (exists && flipY != value) transformChildren(flipYTransform, value);
        return flipY = value;    
    }

    override function set_moves(value:Bool):Bool
    {
        if (exists && moves != value) transformChildren(movesTransform, value);
        return moves = value;
    }

    override function set_immovable(value:Bool):Bool
    {
        if (exists && immovable != value) transformChildren(immovableTransform, value);
        return immovable = value;
    }

    override function set_solid(value:Bool):Bool
    {
        if (exists && solid != value) transformChildren(solidTransform, value);
        return super.set_solid(value);
    }

    override function set_color(value:Int):Int
    {
        if (exists && color != value) transformChildren(gColorTransform, value);
        return color = value;
    }

    override function set_blend(value:BlendMode):BlendMode
    {
        if (exists && blend != value) transformChildren(blendTransform, value);
        return blend = value;
    }

    override function set_clipRect(rect:FlxRect):FlxRect
    {
        if (exists) transformChildren(clipRectTransform, rect);
        return super.set_clipRect(rect);
    }

    override function set_pixelPerfectRender(value:Bool):Bool
    {
        if (exists && pixelPerfectRender != value) transformChildren(pixelPerfectTransform, value);
        return super.set_pixelPerfectRender(value);
    }

    override function set_width(value:Float):Float
        return value;

    override function get_width():Float
    {
        if (this.mainSprite == null) return 0;

        return this.mainSprite.width;
    }

    override function set_height(value:Float):Float
        return value;

    override function get_height():Float
    {
        if (this.mainSprite == null) return 0;

        return this.mainSprite.height;
    }

    public function findMinX():Float
        return this.mainSprite == null ? x : findMinXHelper();

    function findMinXHelper():Float
        return this.mainSprite.x;

    public function findMaxX():Float
        return this.mainSprite == null ? x : findMaxXHelper();

    function findMaxXHelper():Float
        return this.mainSprite.x + this.mainSprite.width;

    public function findMinY():Float
        return this.mainSprite == null ? y : findMinYHelper();

    function findMinYHelper():Float
        return this.mainSprite.y;

    public function findMaxY():Float
        return this.mainSprite == null ? y : findMaxYHelper();

    function findMaxYHelper():Float
        return this.mainSprite.y + this.mainSprite.height;
}