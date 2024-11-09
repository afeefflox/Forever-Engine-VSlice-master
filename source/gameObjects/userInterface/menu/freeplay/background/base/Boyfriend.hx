package gameObjects.userInterface.menu.freeplay.background.base;

import flixel.util.FlxSpriteUtil;
import openfl.display.BlendMode;

class Boyfriend extends Backcard
{
    var moreWays:BGScrollingText;
    var funnyScroll:BGScrollingText;
    var txtNuts:BGScrollingText;
    var funnyScroll2:BGScrollingText;
    var moreWays2:BGScrollingText;
    var funnyScroll3:BGScrollingText;
  
    var glow:FlxSprite;
    var glowDark:FlxSprite;

    public function new()
    {
        super('bf');

        var currentCharacter = PlayerRegistry.instance.fetchEntry(id);
        funnyScroll = new BGScrollingText(0, 220, currentCharacter.getFreeplayDJText(1), FlxG.width / 2, false, 60);
        funnyScroll2 = new BGScrollingText(0, 335, currentCharacter.getFreeplayDJText(1), FlxG.width / 2, false, 60);
        moreWays = new BGScrollingText(0, 160, currentCharacter.getFreeplayDJText(2), FlxG.width, true, 43);
        moreWays2 = new BGScrollingText(0, 397, currentCharacter.getFreeplayDJText(2), FlxG.width, true, 43);
        txtNuts = new BGScrollingText(0, 285, currentCharacter.getFreeplayDJText(3), FlxG.width / 2, true, 43);
        funnyScroll3 = new BGScrollingText(0, orangeBackShit.y + 10, currentCharacter.getFreeplayDJText(1), FlxG.width / 2, 60);
    }

    override function applyExitMovers(?exitMovers:FreeplayState.ExitMoverData, ?exitMoversCharSel:FreeplayState.ExitMoverData)
    {
        super.applyExitMovers(exitMovers, exitMoversCharSel);

        if (exitMovers == null || exitMoversCharSel == null) return;

        exitMovers.set([moreWays],{x: FlxG.width * 2, speed: 0.4,});
        exitMovers.set([funnyScroll],{x: -funnyScroll.width * 2, y: funnyScroll.y, speed: 0.4, wait: 0});
        exitMovers.set([txtNuts], {x: FlxG.width * 2, speed: 0.4});
        exitMovers.set([funnyScroll2],{x: -funnyScroll2.width * 2, speed: 0.5});
        exitMovers.set([moreWays2],{x: FlxG.width * 2, speed: 0.4});
        exitMovers.set([funnyScroll3],{x: -funnyScroll3.width * 2, speed: 0.3});
        exitMoversCharSel.set([moreWays, funnyScroll, txtNuts, funnyScroll2, moreWays2, funnyScroll3],{
            y: -60,
            speed: 0.8,
            wait: 0.1
        });
    }

    override function enterCharSel()
    {
        FlxTween.tween(funnyScroll, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
        FlxTween.tween(funnyScroll2, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
        FlxTween.tween(moreWays, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
        FlxTween.tween(moreWays2, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
        FlxTween.tween(txtNuts, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
        FlxTween.tween(funnyScroll3, {speed: 0}, 0.8, {ease: FlxEase.sineIn});
    }

    override function init()
    {
        FlxTween.tween(pinkBack, {x: 0}, 0.6, {ease: FlxEase.quartOut});
        add(pinkBack);
    
        add(orangeBackShit);
        add(alsoOrangeLOL);
    
        FlxSpriteUtil.alphaMaskFlxSprite(orangeBackShit, pinkBack, orangeBackShit);
        orangeBackShit.visible = alsoOrangeLOL.visible = false;
        
    
        confirmTextGlow.blend = BlendMode.ADD;
        confirmTextGlow.visible = false;
    
        confirmGlow.blend = cardGlow.blend = BlendMode.ADD;
        confirmGlow.visible = confirmGlow2.visible = cardGlow.visible = false;
    
        add(confirmGlow2);
        add(confirmGlow);
    
        add(confirmTextGlow);
        add(backingTextYeah);

        moreWays.visible = funnyScroll.visible = txtNuts.visible = false;
        funnyScroll2.visible = moreWays2.visible = funnyScroll3.visible = false;

        moreWays.funnyColor = 0xFFFFF383;
        moreWays.speed = 6.8;
        add(moreWays);
    
        funnyScroll.funnyColor = 0xFFFF9963;
        funnyScroll.speed = -3.8;
        add(funnyScroll);
    
        txtNuts.speed = 3.5;
        add(txtNuts);
    
        funnyScroll2.funnyColor = 0xFFFF9963;
        funnyScroll2.speed = -3.8;
        add(funnyScroll2);
    
        moreWays2.funnyColor = 0xFFFFF383;
        moreWays2.speed = 6.8;
        add(moreWays2);
    
        funnyScroll3.funnyColor = 0xFFFEA400;
        funnyScroll3.speed = -3.8;
        add(funnyScroll3);
    
        glowDark = new FlxSprite(-300, 330).loadGraphic(Paths.image('$folder/beatglow'));
        glowDark.blend = BlendMode.MULTIPLY;
        add(glowDark);
    
        glow = new FlxSprite(-300, 330).loadGraphic(Paths.image('$folder/beatglow'));
        glow.blend = BlendMode.ADD;
        add(glow);
    
        glowDark.visible = glow.visible = false;
        add(cardGlow);
    }

    var beatFreq:Int = 1;
    var beatFreqList:Array<Int> = [1, 2, 4, 8];
    override function beatHit()
    {
        beatFreq = beatFreqList[Math.floor(Conductor.instance.bpm / 140)];

        if (Conductor.instance.currentBeat % beatFreq != 0) return;
        FlxTween.cancelTweensOf(glow);
        FlxTween.cancelTweensOf(glowDark);
    
        glow.alpha = 0.8;
        FlxTween.tween(glow, {alpha: 0}, 16 / 24, {ease: FlxEase.quartOut});
        glowDark.alpha = 0;
        FlxTween.tween(glowDark, {alpha: 0.6}, 18 / 24, {ease: FlxEase.quartOut});
    }

    override function introDone()
    {
        super.introDone();
        moreWays.visible = true;
        funnyScroll.visible = true;
        txtNuts.visible = true;
        funnyScroll2.visible = true;
        moreWays2.visible = true;
        funnyScroll3.visible = true;
        glowDark.visible = true;
        glow.visible = true;        
    }

    override function confirm()
    {
        super.confirm();
        moreWays.visible = false;
        funnyScroll.visible = false;
        txtNuts.visible = false;
        funnyScroll2.visible = false;
        moreWays2.visible = false;
        funnyScroll3.visible = false;
        glowDark.visible = false;
        glow.visible = false;
    }

    override function disappear()
    {
        super.disappear();
        moreWays.visible = false;
        funnyScroll.visible = false;
        txtNuts.visible = false;
        funnyScroll2.visible = false;
        moreWays2.visible = false;
        funnyScroll3.visible = false;
        glowDark.visible = false;
        glow.visible = false;
    }
}