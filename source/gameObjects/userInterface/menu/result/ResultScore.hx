package gameObjects.userInterface.menu.result;

class ResultScore extends FlxTypedSpriteGroup<ScoreNum>
{
    public var score(default, set):Int = 0;

    public var scoreStart:Int = 0;

    function set_score(val):Int
    {
        if (group == null || group.members == null) return val;
        var loopNum:Int = group.members.length - 1;
        var dumbNumb = Std.parseInt(Std.string(val));
        var prevNum:ScoreNum;
    
        while (dumbNumb > 0)
        {
            scoreStart += 1;
            group.members[loopNum].finalDigit = dumbNumb % 10;
            dumbNumb = Math.floor(dumbNumb / 10);
            loopNum--;
        }

        while (loopNum > 0)
        {
            group.members[loopNum].digit = 10;
            loopNum--;
        }
        return val;
    }

    public function animateNumbers():Void
    {
        for (i in group.members.length-scoreStart...group.members.length)
        {
            new FlxTimer().start((i-1)/24, _ -> {
                group.members[i].finalDelay = scoreStart - (i-1);
                group.members[i].playAnim();
                group.members[i].shuffle();
            });
        }
    }

    public function new(x:Float, y:Float, digitCount:Int, scoreShit:Int = 100, ?styleData:FreeplayStyle)
    {
        super(x, y);

        for (i in 0...digitCount)
            add(new ScoreNum(x + (65 * i), y, styleData ?? null));
    
        this.score = scoreShit;        
    }
}

class ScoreNum extends FunkinSprite
{
  public var digit(default, set):Int = 10;
  public var finalDigit(default, set):Int = 10;
  public var glow:Bool = true;

  function set_finalDigit(val):Int
  {
    animation.play('GONE', true, false, 0);

    return finalDigit = val;
  }

  function set_digit(val):Int
  {
    if (val >= 0 && animation.curAnim != null && animation.curAnim.name != numToString[val])
    {
      if(glow){
        animation.play(numToString[val], true, false, 0);
        glow = false;
      }else{
        animation.play(numToString[val], true, false, 4);
      }
      updateHitbox();
      centerOffsets(false);
    }

    return digit = val;
  }

  public function playAnim():Void
  {
    animation.play(numToString[digit], true, false, 0);
  }

  public var shuffleTimer:FlxTimer;
  public var finalTween:FlxTween;
  public var finalDelay:Float = 0;

  var numToString:Array<String> = [
    "ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "DISABLED"
  ];

  function finishShuffleTween():Void{

    var tweenFunction = function(x) {
      var digitRounded = Math.floor(x);
      //if(digitRounded == finalDigit) glow = true;
      digit = digitRounded;
    };

    finalTween = FlxTween.num(0.0, finalDigit, 23/24, {
      ease: FlxEase.quadOut,
      onComplete: function (input) {
        new FlxTimer().start((finalDelay)/24, _ -> {
          animation.play(animation.curAnim.name, true, false, 0);
        });
        // fuck
      }
    }, tweenFunction);
  }


  function shuffleProgress(shuffleTimer:FlxTimer):Void
  {
    var tempDigit:Int = digit;
    tempDigit += 1;
    if(tempDigit > 9) tempDigit = 0;
    if(tempDigit < 0) tempDigit = 0;
    digit = tempDigit;

    if (shuffleTimer.loops > 0 && shuffleTimer.loopsLeft == 0)
    {
      //digit = finalDigit;
      finishShuffleTween();
    }
  }

  public function shuffle():Void{
    var duration:Float = 41/24;
    var interval:Float = 1/24;
    shuffleTimer = new FlxTimer().start(interval, shuffleProgress, Std.int(duration / interval));
  }

  public function new(x:Float, y:Float, ?styleData:FreeplayStyle)
  {
    super(x, y);

    loadFrame('menus/base/resultScreen/score-digital-numbers-noColor');
    color = styleData.getColor() ?? FlxColor.CYAN; //It cyan I guess :/

    for (i in 0...10)
    {
      var stringNum:String = numToString[i];
      animation.addByPrefix(stringNum, '$stringNum DIGITAL', 24, false);
    }

    animation.addByPrefix('DISABLED', 'DISABLED', 24, false);
    animation.addByPrefix('GONE', 'GONE', 24, false);

    this.digit = 10;

    animation.play(numToString[digit], true);

    updateHitbox();
  }
}