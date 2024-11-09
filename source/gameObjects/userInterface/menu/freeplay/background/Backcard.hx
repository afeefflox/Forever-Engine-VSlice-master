package gameObjects.userInterface.menu.freeplay.background;
import flixel.util.FlxSpriteUtil;
import openfl.display.BlendMode;
class Backcard extends FlxTypedSpriteGroup<FlxSprite>
{
    var _exitMovers:Null<ExitMoverData>;
    var _exitMoversCharSel:Null<ExitMoverData>;

    public var id:String;
    var folder:String = "menus/base/freeplay";

    public var backingTextYeah:FlxAtlasSprite;
    public var orangeBackShit:FunkinSprite;
    public var alsoOrangeLOL:FunkinSprite;
    public var pinkBack:FunkinSprite;
    public var confirmGlow:FlxSprite;
    public var confirmGlow2:FlxSprite;
    public var confirmTextGlow:FlxSprite;
    public var cardGlow:FlxSprite;

    var instance:FreeplayState = FreeplayState.instance;
    public function new(id:String)
    {
        super();
        this.id = id;

        cardGlow = new FlxSprite(-30, -30).loadGraphic(Paths.image('$folder/cardGlow'));
        confirmGlow = new FlxSprite(-30, 240).loadGraphic(Paths.image('$folder/confirmGlow'));
        confirmTextGlow = new FlxSprite(-8, 115).loadGraphic(Paths.image('$folder/glowingText'));
        pinkBack = new FunkinSprite().loadImage('$folder/pinkBack');
        orangeBackShit = new FunkinSprite(84, 440).makeSolidColor(Std.int(pinkBack.width), 75, 0xFFFEDA00);
        alsoOrangeLOL = new FunkinSprite(0, orangeBackShit.y).makeSolidColor(100, Std.int(orangeBackShit.height), 0xFFFFD400);
        confirmGlow2 = new FlxSprite(confirmGlow.x, confirmGlow.y).loadGraphic(Paths.image('$folder/confirmGlow2'));
        backingTextYeah = new FlxAtlasSprite(640, 370, Paths.animateAtlas('$folder/backing-text-yeah'),
        {
            FrameRate: 24.0,
            Reversed: false,
            ShowPivot: false,
            Antialiasing: true,
            ScrollFactor: new FlxPoint(1, 1),
        });
        pinkBack.color = 0xFFFFD4E9; // sets it to pink!
        pinkBack.x -= pinkBack.width;
    }

    public function applyExitMovers(?exitMovers:ExitMoverData, ?exitMoversCharSel:ExitMoverData):Void 
    {
        if (exitMovers == null)
            exitMovers = _exitMovers;
        else
            _exitMovers = exitMovers;

        if (exitMovers == null) return;

        if (exitMoversCharSel == null)
            exitMoversCharSel = _exitMoversCharSel;
        else
            _exitMoversCharSel = exitMoversCharSel;

        if (exitMoversCharSel == null) return;


        exitMovers.set([pinkBack, orangeBackShit, alsoOrangeLOL],
        {
            x: -pinkBack.width,
            y: pinkBack.y,
            speed: 0.4,
            wait: 0
        });
      
        exitMoversCharSel.set([pinkBack],
        {
            y: -100,
            speed: 0.8,
            wait: 0.1
        });
      
        exitMoversCharSel.set([orangeBackShit, alsoOrangeLOL],
        {
            y: -40,
            speed: 0.8,
            wait: 0.1
        });
    }

    public function skipIntroTween()
    {
        FlxTween.cancelTweensOf(pinkBack);
        pinkBack.x = 0;
    }

    public function init() 
    {
        FlxTween.tween(pinkBack, {x: 0}, 0.6, {ease: FlxEase.quartOut});
        add(pinkBack);
        add(orangeBackShit);
        add(alsoOrangeLOL);
    
        FlxSpriteUtil.alphaMaskFlxSprite(orangeBackShit, pinkBack, orangeBackShit);
        orangeBackShit.visible = alsoOrangeLOL.visible = false;

        confirmTextGlow.blend = confirmGlow.blend = BlendMode.ADD;
        confirmTextGlow.visible = false;    
        confirmGlow.visible = confirmGlow2.visible = false;
        
    
        add(confirmGlow2);
        add(confirmGlow);
    
        add(confirmTextGlow);
        add(backingTextYeah);
    
        cardGlow.blend = BlendMode.ADD;
        cardGlow.visible = false;
    
        add(cardGlow);
    }

    public function introDone():Void 
    {
        pinkBack.color = 0xFFFFD863;
        orangeBackShit.visible = true;
        alsoOrangeLOL.visible = true;
        cardGlow.visible = true;
        FlxTween.tween(cardGlow, {alpha: 0, "scale.x": 1.2, "scale.y": 1.2}, 0.45, {ease: FlxEase.sineOut});
    }

    public function confirm():Void 
    {
        FlxTween.color(pinkBack, 0.33, 0xFFFFD0D5, 0xFF171831, {ease: FlxEase.quadOut});
        orangeBackShit.visible = alsoOrangeLOL.visible = false;
        confirmGlow.visible = confirmGlow2.visible = true;
        backingTextYeah.anim.play("");
        confirmGlow2.alpha = confirmGlow.alpha = 0;
        
        FlxTween.color(instance.bgDad, 0.5, 0xFFA8A8A8, 0xFF646464,
        {
            onUpdate: function(_) {
              instance.angleMaskShader.extraColor = instance.bgDad.color;
            }
        });
        FlxTween.tween(confirmGlow2, {alpha: 0.5}, 0.33,
        {
            ease: FlxEase.quadOut,
            onComplete: function(_) {
              confirmGlow2.alpha = 0.6;
              confirmGlow.alpha = 1;
              confirmTextGlow.visible = true;
              confirmTextGlow.alpha = 1;
              FlxTween.tween(confirmTextGlow, {alpha: 0.4}, 0.5);
              FlxTween.tween(confirmGlow, {alpha: 0}, 0.5);
              FlxTween.color(instance.bgDad, 2, 0xFFCDCDCD, 0xFF555555,
                {
                  ease: FlxEase.expoOut,
                  onUpdate: function(_) {
                    instance.angleMaskShader.extraColor = instance.bgDad.color;
                  }
                });
            }
        });        
    }

    public function enterCharSel():Void {}
    public function beatHit():Void {}
    public function disappear():Void 
    {
        FlxTween.color(pinkBack, 0.25, 0xFFFFD863, 0xFFFFD0D5, {ease: FlxEase.quadOut});

        cardGlow.visible = true;
        cardGlow.alpha = 1;
        cardGlow.scale.set(1, 1);
        FlxTween.tween(cardGlow, {alpha: 0, "scale.x": 1.2, "scale.y": 1.2}, 0.25, {ease: FlxEase.sineOut});
    
        orangeBackShit.visible = false;
        alsoOrangeLOL.visible = false;
    }
}