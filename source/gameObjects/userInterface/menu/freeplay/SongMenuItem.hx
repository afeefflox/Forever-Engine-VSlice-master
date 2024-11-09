package gameObjects.userInterface.menu.freeplay;

import flixel.addons.effects.FlxTrail;
import openfl.display.BlendMode;
class SongMenuItem extends FlxSpriteGroup
{
    public var capsule:FlxSprite;

    public var freeplayData(default, null):Null<FreeplaySongData> = null;

    public var selected(default, set):Bool;
  
    public var songText:CapsuleText;
    public var favIconBlurred:FlxSprite;
    public var favIcon:FlxSprite;  
  
    public var ranking:FreeplayRank;
    public var blurredRanking:FreeplayRank;
  
    public var fakeRanking:FreeplayRank;
    public var fakeBlurredRanking:FreeplayRank;
  
    var ranks:Array<String> = ["fail", "average", "great", "excellent", "perfect", "perfectsick"];
  
    public var targetPos:FlxPoint = new FlxPoint();
    public var doLerp:Bool = false;
    public var doJumpIn:Bool = false;
  
    public var doJumpOut:Bool = false;
  
    public var onConfirm:Void->Void;
    public var grayscaleShader:Grayscale;
  
    public var hsvShader(default, set):HSVShader;

    public var bpmText:FlxSprite;
    public var difficultyText:FlxSprite;
    public var bigNumbers:Array<CapsuleNumber> = [];
  
    public var smallNumbers:Array<CapsuleNumber> = [];
    var impactThing:FunkinSprite;
  
    public var sparkle:FlxSprite;

    var icon:HealthIcon;
    var sparkleTimer:FlxTimer;
  
    var folder:String = "menus/base/freeplay";
    public function new(x:Float, y:Float)
    {
        super(x, y);

        capsule = new FlxSprite();
        capsule.frames = Paths.getSparrowAtlas('$folder/freeplayCapsule/freeplayCapsule');
        capsule.animation.addByPrefix('selected', 'mp3 capsule w backing0', 24);
        capsule.animation.addByPrefix('unselected', 'mp3 capsule w backing NOT SELECTED', 24);
        add(capsule);
    
        bpmText = new FlxSprite(144, 87).loadGraphic(Paths.image('$folder/freeplayCapsule/bpmtext'));
        bpmText.setGraphicSize(Std.int(bpmText.width * 0.9));
        add(bpmText);
    
        difficultyText = new FlxSprite(414, 87).loadGraphic(Paths.image('$folder/freeplayCapsule/difficultytext'));
        difficultyText.setGraphicSize(Std.int(difficultyText.width * 0.9));
        add(difficultyText);

        for (i in 0...2)
        {
            var bigNumber:CapsuleNumber = new CapsuleNumber(466 + (i * 30), 32, true, 0);
            add(bigNumber);
            bigNumbers.push(bigNumber);
        }

        for (i in 0...3)
        {
            var smallNumber:CapsuleNumber = new CapsuleNumber(185 + (i * 11), 88.5, false, 0);
            add(smallNumber);
            smallNumbers.push(smallNumber);
        }

        grpHide = new FlxGroup();

        fakeRanking = new FreeplayRank(420, 41);
        add(fakeRanking);
    
        fakeBlurredRanking = new FreeplayRank(fakeRanking.x, fakeRanking.y);
        fakeBlurredRanking.shader = new GaussianBlurShader(1);
        add(fakeBlurredRanking);
    
        fakeRanking.visible = false;
        fakeBlurredRanking.visible = false;
    
        ranking = new FreeplayRank(420, 41);
        add(ranking);
    
        blurredRanking = new FreeplayRank(ranking.x, ranking.y);
        blurredRanking.shader = new GaussianBlurShader(1);
        add(blurredRanking);
    
        sparkle = new FlxSprite(ranking.x, ranking.y);
        sparkle.frames = Paths.getSparrowAtlas('$folder/sparkle');
        sparkle.animation.addByPrefix('sparkle', 'sparkle Export0', 24, false);
        sparkle.animation.play('sparkle', true);
        sparkle.scale.set(0.8, 0.8);
        sparkle.blend = BlendMode.ADD;
    
        sparkle.visible = false;
        sparkle.alpha = 0.7;
        add(sparkle);

        grayscaleShader = new Grayscale(1);

        songText = new CapsuleText(capsule.width * 0.26, 45, 'Random', Std.int(40 * realScaled));
        add(songText);
        grpHide.add(songText);

        updateDifficultyRating(FlxG.random.int(0, 20));

        icon = new HealthIcon('face');
        add(icon);
        grpHide.add(icon);

        favIconBlurred = new FlxSprite(380, 40);
        favIconBlurred.frames = Paths.getSparrowAtlas('$folder/favHeart');
        favIconBlurred.animation.addByPrefix('fav', 'favorite heart', 24, false);
        favIconBlurred.animation.play('fav');
    
        favIconBlurred.setGraphicSize(50, 50);
        favIconBlurred.blend = BlendMode.ADD;
        favIconBlurred.shader = new GaussianBlurShader(1.2);
        favIconBlurred.visible = false;
        add(favIconBlurred);
    
        favIcon = new FlxSprite(favIconBlurred.x, favIconBlurred.y);
        favIcon.frames = Paths.getSparrowAtlas('$folder/favHeart');
        favIcon.animation.addByPrefix('fav', 'favorite heart', 24, false);
        favIcon.animation.play('fav');
        favIcon.setGraphicSize(50, 50);
        favIcon.visible = false;
        favIcon.blend = BlendMode.ADD;
        add(favIcon);

        setVisibleGrp(false);
    }

    function sparkleEffect(timer:FlxTimer):Void
    {
        sparkle.setPosition(FlxG.random.float(ranking.x - 20, ranking.x + 3), FlxG.random.float(ranking.y - 29, ranking.y + 4));
        sparkle.animation.play('sparkle', true);
        sparkleTimer = new FlxTimer().start(FlxG.random.float(1.2, 4.5), sparkleEffect);
    }

    public function checkClip():Void
    {
        var clipSize:Int = 290;
        var clipType:Int = 0;
    
        if (ranking.visible)
        {
            favIconBlurred.x = this.x + 370;
            favIcon.x = favIconBlurred.x;
            clipType += 1;
        }
        else
        {
            favIconBlurred.x = favIcon.x = this.x + 405;
        }
    
        if (favIcon.visible) clipType += 1;
    
        switch (clipType)
        {
            case 2:
                clipSize = 210;
            case 1:
                clipSize = 245;
        }
        songText.clipWidth = clipSize;        
    }

    function updateBPM(newBPM:Int):Void
    {
        var shiftX:Float = 191;
        var tempShift:Float = 0;
    
        if (Math.floor(newBPM / 100) == 1) shiftX = 186;

        for (i in 0...smallNumbers.length)
        {
            smallNumbers[i].x = this.x + (shiftX + (i * 11));
            switch (i)
            {
                case 0:
                    if (newBPM < 100)
                    {
                      smallNumbers[i].digit = 0;
                    }
                    else
                    {
                      smallNumbers[i].digit = Math.floor(newBPM / 100) % 10;
                    }
          
                case 1:
                    if (newBPM < 10)
                    {
                      smallNumbers[i].digit = 0;
                    }
                    else
                    {
                      smallNumbers[i].digit = Math.floor(newBPM / 10) % 10;
          
                      if (Math.floor(newBPM / 10) % 10 == 1) tempShift = -4;
                    }
                case 2:
                    smallNumbers[i].digit = newBPM % 10;
                default:
                    trace('why the fuck is this being called'); 
            }          
            smallNumbers[i].x += tempShift; 
        }
    }

    var evilTrail:FlxTrail;

    public function fadeAnim():Void
    {
        impactThing = new FunkinSprite();
        impactThing.frames = capsule.frames;
        impactThing.frame = capsule.frame;
        impactThing.updateHitbox();

        impactThing.alpha = 0;
        impactThing.zIndex = capsule.zIndex - 3;
        add(impactThing);
        FlxTween.tween(impactThing.scale, {x: 2.5, y: 2.5}, 0.5);

        evilTrail = new FlxTrail(impactThing, null, 15, 2, 0.01, 0.069);
        evilTrail.blend = BlendMode.ADD;
        evilTrail.zIndex = capsule.zIndex - 5;
        FlxTween.tween(evilTrail, {alpha: 0}, 0.6,
        {
            ease: FlxEase.quadOut,
            onComplete: function(_) {
              remove(evilTrail);
            }
        });
        add(evilTrail);

        switch (ranking.rank)
        {
            case SHIT:
                evilTrail.color = 0xFF6044FF;
            case GOOD:
                evilTrail.color = 0xFFEF8764;
            case GREAT:
                evilTrail.color = 0xFFEAF6FF;
            case EXCELLENT:
                evilTrail.color = 0xFFFDCB42;
            case PERFECT:
                evilTrail.color = 0xFFFF58B4;
            case PERFECT_GOLD:
                evilTrail.color = 0xFFFFB619;
        }
    }

    public function getTrailColor():FlxColor return evilTrail.color;


    public function refreshDisplay():Void
    {
        if (freeplayData == null)
        {
            songText.text = 'Random';
            icon.visible = false;
            ranking.visible = false;
            blurredRanking.visible = false;
            favIcon.visible = false;
            favIconBlurred.visible = false;
        }
        else
        {
            songText.text = freeplayData.fullSongName;
            if (freeplayData.data.songCharacter != null) icon.char = CharacterRegistry.fetchCharacterData(freeplayData.data.songCharacter).healthIcon.id;
            icon.visible = true;
            updateBPM(Std.int(freeplayData.songStartingBpm) ?? 0);
            updateDifficultyRating(freeplayData.difficultyRating ?? 0);
            updateScoringRank(freeplayData.scoringRank);
            favIcon.visible = freeplayData.isFav;
            favIconBlurred.visible = freeplayData.isFav;
            checkClip();
        }
        updateSelected();
    }

    function updateDifficultyRating(newRating:Int):Void
    {
        var ratingPadded:String = newRating < 10 ? '0$newRating' : '$newRating';

        for (i in 0...bigNumbers.length)
        {
            switch (i)
            {
              case 0:
                if (newRating < 10)
                {
                  bigNumbers[i].digit = 0;
                }
                else
                {
                  bigNumbers[i].digit = Math.floor(newRating / 10);
                }
              case 1:
                bigNumbers[i].digit = newRating % 10;
              default:
                trace('why the fuck is this being called');
            }
        }
    }

    function updateScoringRank(newRank:Null<ScoringRank>):Void
    {
        if (sparkleTimer != null) sparkleTimer.cancel();
        sparkle.visible = false;
    
        this.ranking.rank = newRank;
        this.blurredRanking.rank = newRank;
    
        if (newRank == PERFECT_GOLD)
        {
            sparkleTimer = new FlxTimer().start(1, sparkleEffect);
            sparkle.visible = true;
        }
    }

    function set_hsvShader(value:HSVShader):HSVShader
    {
        this.hsvShader = value;
        capsule.shader = hsvShader;
        songText.shader = hsvShader;
    
        return value;
    }

    function textAppear():Void
    {
        songText.scale.x = 1.7;
        songText.scale.y = 0.2;
    
        new FlxTimer().start(1 / 24, function(_) {
          songText.scale.x = 0.4;
          songText.scale.y = 1.4;
        });
    
        new FlxTimer().start(2 / 24, function(_) {
          songText.scale.x = songText.scale.y = 1;
        });
    }

    function setVisibleGrp(value:Bool):Void
    {
        for (spr in grpHide.members) spr.visible = value;
        if (value) textAppear();

        updateSelected();
    }

    public function init(?x:Float, ?y:Float, freeplayData:Null<FreeplaySongData>):Void
    {
        if (x != null) this.x = x;
        if (y != null) this.y = y;
        this.freeplayData = freeplayData;


        updateScoringRank(freeplayData?.scoringRank);
        favIcon.animation.curAnim.curFrame = favIcon.animation.curAnim.numFrames - 1;
        favIconBlurred.animation.curAnim.curFrame = favIconBlurred.animation.curAnim.numFrames - 1;
    
        refreshDisplay();
    }

    var frameInTicker:Float = 0;
    var frameInTypeBeat:Int = 0;
  
    var frameOutTicker:Float = 0;
    var frameOutTypeBeat:Int = 0;
  
    var xFrames:Array<Float> = [1.7, 1.8, 0.85, 0.85, 0.97, 0.97, 1];
    var xPosLerpLol:Array<Float> = [0.9, 0.4, 0.16, 0.16, 0.22, 0.22, 0.245]; // NUMBERS ARE JANK CUZ THE SCALING OR WHATEVER
    var xPosOutLerpLol:Array<Float> = [0.245, 0.75, 0.98, 0.98, 1.2]; // NUMBERS ARE JANK CUZ THE SCALING OR WHATEVER
  
    public var realScaled:Float = 0.8;

    
    public function initJumpIn(maxTimer:Float, ?force:Bool):Void
    {
        frameInTypeBeat = 0;

        new FlxTimer().start((1 / 24) * maxTimer, function(doShit) {
          doJumpIn = true;
        });
    
        new FlxTimer().start((0.09 * maxTimer) + 0.85, function(lerpTmr) {
          doLerp = true;
        });

        if (force)
        {
            visible = true;
            capsule.alpha = 1;
            setVisibleGrp(true);
        }
        else
        {
            new FlxTimer().start((xFrames.length / 24) * 2.5, function(_) {
                visible = true;
                capsule.alpha = 1;
                setVisibleGrp(true);
            });
        }
    }

    var grpHide:FlxGroup;

    public function forcePosition():Void
    {
        visible = true;
        capsule.alpha = 1;
        updateSelected();
        doLerp = true;
        doJumpIn = false;
        doJumpOut = false;
    
        frameInTypeBeat = xFrames.length;
        frameOutTypeBeat = 0;
    
        capsule.scale.x = xFrames[frameInTypeBeat - 1];
        capsule.scale.y = 1 / xFrames[frameInTypeBeat - 1];
        x = targetPos.x;
        y = targetPos.y;
    
        capsule.scale.x *= realScaled;
        capsule.scale.y *= realScaled;
    
        setVisibleGrp(true);
    }

    override function update(elapsed:Float):Void
    {
        if (impactThing != null) impactThing.angle = capsule.angle;

        if (doJumpIn)
        {
            frameInTicker += elapsed;

            if (frameInTicker >= 1 / 24 && frameInTypeBeat < xFrames.length)
            {
                frameInTicker = 0;
      
                capsule.scale.x = xFrames[frameInTypeBeat];
                capsule.scale.y = 1 / xFrames[frameInTypeBeat];
                x = FlxG.width * xPosLerpLol[Std.int(Math.min(frameInTypeBeat, xPosLerpLol.length - 1))];
        
                capsule.scale.x *= realScaled;
                capsule.scale.y *= realScaled;
        
                frameInTypeBeat += 1;
            }            
        }

        if (doJumpOut)
        {
            frameOutTicker += elapsed;

            if (frameOutTicker >= 1 / 24 && frameOutTypeBeat < xFrames.length)
            {
                frameOutTicker = 0;

                capsule.scale.x = xFrames[frameOutTypeBeat];
                capsule.scale.y = 1 / xFrames[frameOutTypeBeat];
                x = FlxG.width * xPosOutLerpLol[Std.int(Math.min(frameOutTypeBeat, xPosOutLerpLol.length - 1))];
        
                capsule.scale.x *= realScaled;
                capsule.scale.y *= realScaled;
        
                frameOutTypeBeat += 1;
            }
        }

        if (doLerp)
        {
            x = MathUtil.coolLerp(x, targetPos.x, 0.3);
            y = MathUtil.coolLerp(y, targetPos.y, 0.4);
        }
        super.update(elapsed);
    }

    public function confirm():Void
    {
        if (songText != null) songText.flickerText();
    }

    public function intendedY(index:Int):Float 
    {
        return (index * ((height * realScaled) + 10)) + 120;
    }

    function set_selected(value:Bool):Bool
    {
        selected = value;
        updateSelected();
        return selected;
    }

    function updateSelected():Void
    {
        grayscaleShader.setAmount(this.selected ? 0 : 0.8);
        songText.alpha = this.selected ? 1 : 0.6;
        songText.blurredText.visible = this.selected ? true : false;
        capsule.offset.x = this.selected ? 0 : -5;
        capsule.animation.play(this.selected ? "selected" : "unselected");
        ranking.alpha = this.selected ? 1 : 0.7;
        favIcon.alpha = this.selected ? 1 : 0.6;
        favIconBlurred.alpha = this.selected ? 1 : 0;
        ranking.color = this.selected ? 0xFFFFFFFF : 0xFFAAAAAA;
    
        if (songText.tooLong) songText.resetText();
    
        if (selected && songText.tooLong) songText.initMove();
    }
}

class FreeplayRank extends FlxSprite
{
    public var rank(default, set):Null<ScoringRank> = null;

    function set_rank(val:Null<ScoringRank>):Null<ScoringRank>
    {
        rank = val;

        if (rank == null || val == null)
            this.visible = false;
        else
        {
            this.visible = true;
            animation.play(val.getFreeplayRankIconAsset(), true, false);

            centerOffsets(false);
            
            switch (val)
            {
                case GOOD, GREAT:
                    offset.y -= 8;
                default:
                    centerOffsets(false);
                    this.visible = false;
            }
            updateHitbox();
        }
        return rank;
    }

    public function new(x:Float, y:Float)
    {
        super(x, y);

        frames = Paths.getSparrowAtlas('menus/base/freeplay/rankbadges');
        animation.addByPrefix('PERFECT', 'PERFECT rank', 24, false);
        animation.addByPrefix('EXCELLENT', 'EXCELLENT rank', 24, false);
        animation.addByPrefix('GOOD', 'GOOD rank', 24, false);
        animation.addByPrefix('PERFECTSICK', 'PERFECT rank GOLD', 24, false);
        animation.addByPrefix('GREAT', 'GREAT rank', 24, false);
        animation.addByPrefix('LOSS', 'LOSS rank', 24, false);

        blend = BlendMode.ADD;
        this.rank = null;
        scale.set(0.9, 0.9);
        updateHitbox();
    }
}


class CapsuleNumber extends FlxSprite
{
  public var digit(default, set):Int = 0;

  function set_digit(val):Int
  {
    animation.play(numToString[val], true, false, 0);

    centerOffsets(false);

    switch (val)
    {
      case 1:
        offset.x -= 4;
      case 3:
        offset.x -= 1;

      case 6:

      case 4:
        // offset.y += 5;
      case 9:
        // offset.y += 5;
      default:
        centerOffsets(false);
    }
    return val;
  }

  public var baseY:Float = 0;
  public var baseX:Float = 0;

  var numToString:Array<String> = ["ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE"];

  public function new(x:Float, y:Float, big:Bool = false, ?initDigit:Int = 0)
  {
    super(x, y);
    var name:String = big ? 'big' : 'small';
    frames = Paths.getSparrowAtlas('menus/base/freeplay/freeplayCapsule/${name}numbers');
    for (i in 0...10)
    {
      var stringNum:String = numToString[i];
      animation.addByPrefix(stringNum, '$stringNum', 24, false);
    }

    this.digit = initDigit;

    animation.play(numToString[initDigit], true);

    setGraphicSize(Std.int(width * 0.9));
    updateHitbox();
  }
}