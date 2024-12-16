package gameObjects.userInterface.menu.freeplay;

class LetterSort extends FlxTypedSpriteGroup<FlxSprite>
{
    public var letters:Array<FreeplayLetter> = [];

    // starts at 2, cuz that's the middle letter on start (accounting for fav and #, it should begin at ALL filter)
    var curSelection:Int = 2;
  
    public var changeSelectionCallback:String->Void;
  
    var leftArrow:FlxSprite;
    var rightArrow:FlxSprite;
    var grpSeperators:Array<FlxSprite> = [];
    public var inputEnabled:Bool = true;
    var folder:String = "menus/base/freeplay";
    public function new(x, y)
    {
        super(x, y);

        leftArrow = new FlxSprite(-20, 15).loadGraphic(Paths.image('$folder/miniArrow'));
        leftArrow.flipX = true;
        add(leftArrow);

        for (i in 0...5)
        {
            var letter:FreeplayLetter = new FreeplayLetter(i * 80, 0, i);
            letter.x += 50;
            letter.y += 50;
            add(letter);
      
            letters.push(letter);
      
            if (i != 2) letter.scale.x = letter.scale.y = 0.8;
      
            var darkness:Float = Math.abs(i - 2) / 6;
            letter.color = letter.color.getDarkened(darkness);
      
            // don't put the last seperator
            if (i == 4) continue;
      
            var sep:FlxSprite = new FlxSprite((i * 80) + 60, 20).loadGraphic(Paths.image('$folder/seperator'));
            sep.color = letter.color.getDarkened(darkness);
            add(sep);
      
            grpSeperators.push(sep);
        }

        rightArrow = new FlxSprite(380, 15).loadGraphic(Paths.image('$folder/miniArrow'));
        add(rightArrow);
        changeSelection();        
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (inputEnabled)
        {
            if (PlayerSettings.player1.controls.FREEPLAY_LEFT) changeSelection(-1);
            if (PlayerSettings.player1.controls.FREEPLAY_RIGHT) changeSelection(1);
        }
    }
    
    public function changeSelection(?diff:Int = 0):Void
    {
        doLetterChangeAnims(diff);

        var multiPosOrNeg:Float = diff > 0 ? 1 : -1;
    
        // if we're moving left (diff < 0), we want control of the right arrow, and vice versa
        var arrowToMove:FlxSprite = diff < 0 ? leftArrow : rightArrow;
        arrowToMove.offset.x = 3 * multiPosOrNeg;
    
        new FlxTimer().start(2 / 24, function(_) {
          arrowToMove.offset.x = 0;
        });
    }

    function doLetterChangeAnims(diff:Int):Void
    {
        var ezTimer:Int->FlxSprite->Float->Void = function(frameNum:Int, spr:FlxSprite, offsetNum:Float) {
            new FlxTimer().start(frameNum / 24, function(_) {
              spr.offset.x = offsetNum;
            });
        };

        var positions:Array<Float> = [-10, -22, 2, 0];

        // if we're moving left, we want to move the positions the same amount, but negative direciton
        var multiPosOrNeg:Float = diff > 0 ? 1 : -1;

        for (sep in grpSeperators)
        {
            ezTimer(0, sep, positions[0] * multiPosOrNeg);
            ezTimer(1, sep, positions[1] * multiPosOrNeg);
            ezTimer(2, sep, positions[2] * multiPosOrNeg);
            ezTimer(3, sep, positions[3] * multiPosOrNeg);
        }

        for (index => letter in letters)
        {
            letter.offset.x = positions[0] * multiPosOrNeg;

            new FlxTimer().start(1 / 24, function(_) {
              letter.offset.x = positions[1] * multiPosOrNeg;
              if (index == 0) letter.visible = false;
            });
      
            new FlxTimer().start(2 / 24, function(_) {
              letter.offset.x = positions[2] * multiPosOrNeg;
              if (index == 0.) letter.visible = true;
            });

            if (index == 2)
            {
                ezTimer(3, letter, 0);
                continue;
            }
          
            ezTimer(3, letter, positions[3] * multiPosOrNeg);


            curSelection += diff;
            if (curSelection < 0) curSelection = letters[0].regexLetters.length - 1;
            if (curSelection >= letters[0].regexLetters.length) curSelection = 0;
            for (letter in letters)  letter.changeLetter(diff, curSelection);
            if (changeSelectionCallback != null) changeSelectionCallback(letters[2].regexLetters[letters[2].curLetter]); // bullshit and long lol!            
        }
    }
}

class FreeplayLetter extends FlxAtlasSprite
{
    public var regexLetters:Array<String> = [];
    public var animLetters:Array<String> = [];

    public var curLetter:Int = 0;

    public function new(x:Float, y:Float, ?letterInd:Int)
    {
        super(x, y, Paths.animateAtlas("menus/base/freeplay/sortedLetters"));

        var alphabet:String = 'A-B_C-D_E-H_I-L_M-N_O-R_S_T_U-Z';
        regexLetters = alphabet.split('_');
        regexLetters.insert(0, 'ALL');
        regexLetters.insert(0, 'fav');
        regexLetters.insert(0, '#');

        animLetters = regexLetters.map(animLetter -> animLetter.replace('-', ''));

        if (letterInd != null)
        {
            this.anim.play(animLetters[letterInd] + " move");
            this.anim.pause();
            curLetter = letterInd;
        }
    }

    public function changeLetter(diff:Int = 0, ?curSelection:Int):Void
    {
        curLetter += diff;

        if (curLetter < 0) curLetter = regexLetters.length - 1;
        if (curLetter >= regexLetters.length) curLetter = 0;
    
        var animName:String = animLetters[curLetter] + ' move';
        switch (animLetters[curLetter])
        {
            case "IL":
                animName = "IL move";
            case "s":
                animName = "S move";
            case "t":
                animName = "T move";
        }

        this.anim.play(animName);
        if (curSelection != curLetter) this.anim.pause();
    }
}