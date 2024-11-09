package gameObjects.userInterface.menu.freeplay;

class FreeplayScore extends FlxTypedSpriteGroup<ScoreNum>
{
    public var score(default, set):Int = 0;

    function set_score(val):Int
    {
        if (group == null || group.members == null) return val;
        var loopNum:Int = group.members.length - 1;
        var dumbNumb = Std.parseInt(Std.string(val));
        var prevNum:ScoreNum;
    
        while (dumbNumb > 0)
        {
            group.members[loopNum].digit = dumbNumb % 10;
            dumbNumb = Math.floor(dumbNumb / 10);
            loopNum--;
        }

        while (loopNum > 0)
        {
            group.members[loopNum].digit = 0;
            loopNum--;
        }
        
        return val;
    }

    public function new(x:Float, y:Float, digitCount:Int, scoreShit:Int = 100)
    {
        super(x, y);

        for (i in 0...digitCount)
        {
            add(new ScoreNum(x + (45 * i), y, 0));
        }
    
        this.score = scoreShit;
    }
}

class ScoreNum extends FlxSprite
{
    public var digit(default, set):Int = 0;

    function set_digit(val):Int
    {
        if (animation.curAnim != null && animation.curAnim.name != numToString[val])
        {
            animation.play(numToString[val], true, false, 0);
            updateHitbox();
      
            switch (val)
            {
                case 1:
                    offset.x -= 15;
                default:
                    centerOffsets(false);
            }
        }
        return val;
    }
    
    var numToString:Array<String> = ["ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE"];
    var folder:String = "menus/base/freeplay";
    public function new(x:Float, y:Float, ?initDigit:Int = 0)
    {
        super(x, y);

        frames = Paths.getSparrowAtlas('$folder/digital_numbers');

        for (i in 0...10)
        {
            var stringNum:String = numToString[i];
            animation.addByPrefix(stringNum, '$stringNum DIGITAL', 24, false);
        }

        this.digit = initDigit;

        animation.play(numToString[digit], true);
    
        setGraphicSize(Std.int(width * 0.4));
        updateHitbox();
    }
}