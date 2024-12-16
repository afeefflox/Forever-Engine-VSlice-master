package gameObjects.character;

import data.CharacterData.CharacterRenderType;
import flixel.util.FlxDestroyUtil;
import meta.modding.events.ScriptEvent;
import flxanimate.animate.FlxKeyFrame;

class AnimateAtlasCharacter extends BaseCharacter 
{
    public var mainSprite:FlxAnimate;
    var animsMap:Map<String, AnimationData> = new Map<String, AnimationData>();
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

        this.mainSprite = new FlxAnimate(0, 0, Paths.animateAtlas(_data.assetPath));
        this.mainSprite.antialiasing = _data.antialiasing;
    }

    function loadAnimations()
    {
        trace('[ATLASANIMATECHAR] Loading ${_data.animations.length} animations for ${id}');
        for (anim in _data.animations) addAnimation(anim);

        var animNames = this.mainSprite.anim.getNameList();
        trace('[ATLASANIMATECHAR] Successfully loaded ${animNames.length} animations for ${id}');        
    }

    public function addAnimation(anim:AnimationData)
    {
        var frameRate = anim.frameRate == null ? 24 : anim.frameRate;
        var looped = anim.looped == null ? false : anim.looped;

        if(this.mainSprite.anim.symbolDictionary.exists(anim.name))
        {
            if (anim.frameIndices != null && anim.frameIndices.length > 0)
                this.mainSprite.anim.addBySymbolIndices(anim.name, anim.prefix, anim.frameIndices, frameRate, looped);
            else
                this.mainSprite.anim.addBySymbol(anim.name, anim.prefix, frameRate, looped);
        }
        else if (this.mainSprite.anim.getFrameLabel(anim.prefix) != null)
            this.mainSprite.anim.addBySymbolIndices(anim.name, this.mainSprite.anim.stageInstance.symbol.name, this.mainSprite.anim.getFrameLabel(anim.prefix).getFrameIndices(), frameRate, looped);

        if (anim.offsets == null)
            setAnimationOffsets(anim.name, 0, 0);
        else
            setAnimationOffsets(anim.name, anim.offsets[0], anim.offsets[1]);
    }

    public override function playAnim(name:String, restart:Bool = false, ignoreOther:Bool = false, reverse:Bool = false):Void
    {
        if (!canPlayOtherAnims && !ignoreOther) return;

        var correctName = correctAnimationName(name);
        if (correctName == null) return;

        this.mainSprite.anim.play(correctName, restart, reverse);
        
        if (ignoreOther) canPlayOtherAnims = false;

        applyAnimationOffsets(correctName);
    }

    public override function hasAnimation(name:String):Bool
    {
        if (this.mainSprite.anim == null) return false;
        return this.mainSprite.anim.getByName(name) != null;
    }

    public override function isAnimationFinished():Bool
        return this.mainSprite.anim.finished;

    override function get_animPaused():Bool
        return this.mainSprite.anim.isPlaying;

    override function set_animPaused(value:Bool):Bool
    {
        if(value) this.mainSprite.anim.pause();
        else this.mainSprite.anim.resume();
        return value;        
    }

    override function getCurrentAnimation():String
    {
        if (this.mainSprite.anim == null || this.mainSprite.anim.curSymbol == null) return "";
        return this.mainSprite.anim.lastPlayedAnim;
    }

    override function finishAnimation()
        this.mainSprite.anim.curFrame = this.mainSprite.anim.length - 1;

    override function isAnimationNull():Bool
    {
        return (this.mainSprite.anim == null || this.mainSprite.anim.curSymbol == null);
    }

    public override function draw()
    {
        copyAtlasValues();
		this.mainSprite.draw();
    }

    public function copyAtlasValues()
    {
        @:privateAccess
		{
			this.mainSprite.cameras = cameras;
			this.mainSprite.scrollFactor = scrollFactor;
			this.mainSprite.scale = scale;
			this.mainSprite.offset = offset;
			this.mainSprite.origin = origin;
			this.mainSprite.x = x;
			this.mainSprite.y = y;
			this.mainSprite.angle = angle;
			this.mainSprite.alpha = alpha;
			this.mainSprite.visible = visible;
			this.mainSprite.flipX = flipX;
			this.mainSprite.flipY = flipY;
			this.mainSprite.shader = shader;
			this.mainSprite.antialiasing = antialiasing;
			this.mainSprite.colorTransform = colorTransform;
			this.mainSprite.color = color;
            this.mainSprite.width = width;
            this.mainSprite.height = height;
		}
    }

    public override function destroy()
    {
        if (this.mainSprite != null)
			this.mainSprite = FlxDestroyUtil.destroy(this.mainSprite);
        super.destroy();
    }

    override function update(elapsed:Float)
        this.mainSprite.update(elapsed);

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
}