package audio.visualize;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.sound.FlxSound;
import funkin.vis.dsp.SpectralAnalyzer;

class ABotVis extends FlxTypedSpriteGroup<FlxSprite>
{
    public function new(x:Float, y:Float)
    {
        super(x, y);

        var positionX:Array<Float> = [0, 59, 56, 66, 54, 52, 51];
        var positionY:Array<Float> = [0, -8, -3.5, -0.4, 0.5, 4.7, 7];

        for (i in 1...8)
        {
            var posX:Float = 0;
            var posY:Float = 0;            
            posX += positionX[i-1];
			posY += positionY[i-1];
      
            var viz:FunkinSprite = new FunkinSprite(posX, posY).loadFrame('characters/abot/viz');
            viz.animation.addByPrefix('VIZ', 'viz$i', 0);
            viz.animation.play('VIZ', false, false, 6);
            add(viz);
        }
    }

    static inline function min(x:Int, y:Int):Int return x > y ? y : x;


    #if funkin.vis
    var analyzer:SpectralAnalyzer;

    public function initAnalyzer(snd:FlxSound)
    {
        @:privateAccess
        analyzer = new SpectralAnalyzer(snd._channel.__audioSource, 7, 0.1, 40);
        #if desktop
		analyzer.fftN = 256;
		#end
    }

    override function draw()
    {
        if (analyzer != null) drawFFT();
        super.draw();
    }

    function drawFFT():Void
    {
        var levels = analyzer.getLevels();

        for (i in 0...min(members.length, levels.length))
        {
            var animFrame:Int = Math.round(levels[i].value * 5);
            animFrame = Math.floor(Math.min(5, animFrame));
            animFrame = Math.floor(Math.max(0, animFrame));
            animFrame = Std.int(Math.abs(animFrame - 5)); // shitty dumbass flip, cuz dave got da shit backwards lol!
            group.members[i].animation.curAnim.curFrame = animFrame;
        }
    }

    #end
}