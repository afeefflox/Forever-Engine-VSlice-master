package gameObjects.userInterface.menu.charSelect;

import meta.util.FramesJSFLParser;
import meta.util.FramesJSFLParser.FramesJSFLInfo;
import meta.util.FramesJSFLParser.FramesJSFLFrame;
import funkin.vis.dsp.SpectralAnalyzer;

class GF extends FlxAtlasSprite implements IBPMSyncedScriptedClass
{
    var fadeTimer:Float = 0;
    var fadingStatus:FadeStatus = OFF;
    var fadeAnimIndex:Int = 0;
  
    var animInInfo:FramesJSFLInfo;
    var animOutInfo:FramesJSFLInfo;
  
    var intendedYPos:Float = 0;
    var intendedAlpha:Float = 0;
    var list:Array<String> = [];
  
    var analyzer:SpectralAnalyzer;
  
    var currentGFPath:Null<String>;
    var enableVisualizer:Bool = false; 
    
    var folder:String = "menus/base/charSelect/chill";
    public function new()
    {
        super(0, 0, Paths.animateAtlas('$folder/gf'));

        list = anim.curSymbol.getFrameLabelNames();
    
        switchGF("bf");
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        switch (fadingStatus)
        {
          case OFF:
            // do nothing if it's off!
            // or maybe force position to be 0,0?
            // maybe reset timers?
            resetFadeAnimParams();
          case FADE_OUT:
            doFade(animOutInfo);
          case FADE_IN:
            doFade(animInInfo);
          default:
        }        
    }

    public function onStepHit(event:SongTimeScriptEvent):Void {}

    var danceEvery:Int = 2;
  
    public function onBeatHit(event:SongTimeScriptEvent):Void
    {
      if (getCurrentAnimation() == "idle" && (event.beat % danceEvery == 0))
        {
          trace('GF beat hit');
          playAnimation("idle", true, false, false);
        }
    }

    override public function draw()
    {
        if (analyzer != null) drawFFT();
        super.draw();
    }

    function drawFFT()
    {
        if (anim.curSymbol.timeline.get("VIZ_bars") != null)
        {
            var levels = analyzer.getLevels();
            var frame = anim.curSymbol.timeline.get("VIZ_bars").get(anim.curFrame);
            var elements = frame.getList();
            var len:Int = cast Math.min(elements.length, 7);

            for (i in 0...len)
            {
                var animFrame:Int = Math.round(levels[i].value * 12);
                animFrame = Math.floor(Math.min(12, animFrame));
                animFrame = Math.floor(Math.max(0, animFrame));
                animFrame = Std.int(Math.abs(animFrame - 12)); // shitty dumbass flip, cuz dave got da shit backwards lol!
                elements[i].symbol.firstFrame = animFrame;
            }
        }
    }

    function doFade(animInfo:FramesJSFLInfo):Void
    {
        fadeTimer += FlxG.elapsed;
        if (fadeTimer >= 1 / 24)
        {
          fadeTimer -= FlxG.elapsed;
          // only inc the index for the first frame, used for reference of where to "start"
          if (fadeAnimIndex == 0)
          {
            fadeAnimIndex++;
            return;
          }
    
          var curFrame:FramesJSFLFrame = animInfo.frames[fadeAnimIndex];
          var prevFrame:FramesJSFLFrame = animInfo.frames[fadeAnimIndex - 1];
    
          var xDiff:Float = curFrame.x - prevFrame.x;
          var yDiff:Float = curFrame.y - prevFrame.y;
          var alphaDiff:Float = curFrame.alpha - prevFrame.alpha;
          alphaDiff /= 100; // flash exports alpha as a whole number
    
          alpha += alphaDiff;
          alpha = FlxMath.bound(alpha, 0, 1);
          x += xDiff;
          y += yDiff;
    
          fadeAnimIndex++;
        }
    
        if (fadeAnimIndex >= animInfo.frames.length) fadingStatus = OFF;        
    }

    function resetFadeAnimParams()
    {
        fadeTimer = 0;
        fadeAnimIndex = 0;
    }

    public function switchGF(bf:String):Void
    {
        var previousGFPath = currentGFPath;

        var bfObj = PlayerRegistry.instance.fetchEntry(bf);
        var gfData = bfObj?.getCharSelectData()?.gf;
        currentGFPath = gfData?.assetPath != null ? Paths.animateAtlas(gfData?.assetPath) : null;
        trace('currentGFPath(${currentGFPath})');
        if (currentGFPath == null)
        {
          this.visible = false;
          return;
        }
        else if (previousGFPath != currentGFPath)
        {
            this.visible = true;
            loadAtlas(currentGFPath);

            var animInfoPath = Paths.file('images/${gfData?.animInfoPath}');
            animInInfo = FramesJSFLParser.parse(animInfoPath + '/In.txt');
            animOutInfo = FramesJSFLParser.parse(animInfoPath + '/Out.txt');            
        }

        playAnimation("idle", true, false, false);
        updateHitbox();
    }

    public function onScriptEvent(event:ScriptEvent):Void {};
    public function onCreate(event:ScriptEvent):Void {};
    public function onDestroy(event:ScriptEvent):Void {};
    public function onUpdate(event:UpdateScriptEvent):Void {};
} 

enum FadeStatus
{
  OFF;
  FADE_OUT;
  FADE_IN;
}