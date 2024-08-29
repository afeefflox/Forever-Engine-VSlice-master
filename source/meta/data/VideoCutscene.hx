package meta.data;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
enum CutsceneType
{
    STARTING; // The default cutscene type. Starts the countdown after the video is done.
    MIDSONG; // Does nothing.
    ENDING; // Ends the song after the video is done.
}

class VideoCutscene
{
    static var blackScreen:FlxSprite;
    static var cutsceneType:CutsceneType;
    static var vid:FlxVideoSprite;

    public static final onVideoStarted:FlxSignal = new FlxSignal();
    public static final onVideoPaused:FlxSignal = new FlxSignal();
    public static final onVideoResumed:FlxSignal = new FlxSignal();
    public static final onVideoRestarted:FlxSignal = new FlxSignal();
    public static final onVideoEnded:FlxSignal = new FlxSignal();

    public static function play(filePath:String, ?cutsceneType:String = 'start'):Void
    {
        PlayState.instance.inCutscene = true;
        PlayState.instance.camHUD.visible = false;
        PlayState.instance.camAlt.visible = true;

        blackScreen = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
        blackScreen.scrollFactor.set();
        blackScreen.camera = PlayState.instance.camAlt;
        FlxG.state.add(blackScreen);
        VideoCutscene.cutsceneType = setStringToEnum(cutsceneType);

        vid = new FlxVideoSprite();
        if (vid != null)
        {
            vid.bitmap.onEndReached.add(finish.bind(0.5));
            vid.bitmap.onFormatSetup.add(function()
            {
                vid.setGraphicSize(FlxG.width);
                vid.updateHitbox();
                vid.screenCenter();
            });
            vid.autoPause = false;
            vid.camera = PlayState.instance.camAlt;
            FlxG.state.add(vid);

            vid.load(filePath + '.mp4');
            vid.play();
            onVideoStarted.dispatch();
        }
    }

    public static function isPlaying():Bool
        return vid != null;

    public static function restart(resume:Bool = true):Void
    {
        if (vid != null)
        {
            // Seek to the start of the video.
            vid.bitmap.time = 0;
            if (resume) vid.resume();
            onVideoRestarted.dispatch();
        }
    }

    public static function pause():Void
    {
        if (vid != null)
        {
            vid.pause();
            onVideoPaused.dispatch();
        }
    }

    public static function hide():Void
    {  
        if (vid != null) vid.visible = blackScreen.visible = false;
    }

    public static function show():Void
    {
        if (vid != null)
        {
            blackScreen.visible = false;
            vid.visible = true;
        }
    }

    public static function resume():Void
    {
        if (vid != null)
        {
            vid.resume();
            onVideoResumed.dispatch();
        }
    }

    public static function finish(?transitionTime:Float = 0.5):Void
    {
        var cutsceneType:CutsceneType = VideoCutscene.cutsceneType;

        if (vid != null)
        {
            vid.stop();
            FlxG.state.remove(vid);
        }

        PlayState.instance.camHUD.visible = true;
        FlxTween.tween(blackScreen, {alpha: 0}, transitionTime,
        {
            ease: FlxEase.quadInOut,
            onComplete: function(twn:FlxTween) {
                FlxG.state.remove(blackScreen);
                blackScreen = null;
            }
        });
        FlxTween.tween(FlxG.camera, {zoom: PlayState.instance.stageZoom}, transitionTime, {ease: FlxEase.quadInOut,
            onComplete: function(twn:FlxTween) {
                onVideoEnded.dispatch();
                onCutsceneFinish(cutsceneType);
            }
        });
    }

    static function onCutsceneFinish(cutsceneType:CutsceneType):Void
    {
        switch (cutsceneType)
        {
            case CutsceneType.STARTING:
                PlayState.instance.startCountdown();
            case CutsceneType.ENDING:
                PlayState.instance.endSong();
            default:
                //do Nothing
        }
    }

    static function setStringToEnum(type:String):CutsceneType
    {
        switch(type.trim().toLowerCase())
        {
            case 'start':
                return CutsceneType.STARTING;
            case 'end':
                return CutsceneType.ENDING;
        }
        return CutsceneType.MIDSONG;
    }
}
#end