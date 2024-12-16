package meta.subState;
import gameObjects.userInterface.menu.result.*;
import flixel.text.FlxBitmapText;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
class ResultSubState extends MusicBeatSubState
{
    var params:ResultsStateParams;

    var rank:ScoringRank;
    var songName:FlxBitmapText;
    var difficulty:FunkinSprite;
    var clearPercentSmall:ClearPercentCounter;
  
    var maskShaderSongName:LeftMaskShader = new LeftMaskShader();
    var maskShaderDifficulty:LeftMaskShader = new LeftMaskShader();
  
    var resultsAnim:FunkinSprite;
    var ratingsPopin:FunkinSprite;
    var scorePopin:FunkinSprite;
  
    var bgFlash:FlxSprite;
  
    var highscoreNew:FunkinSprite;
    var score:ResultScore;
    var characterAtlasAnimations:Array<{
        sprite:FlxAtlasSprite,
        delay:Float,
        forceLoop:Bool
    }> = [];
    var characterSparrowAnimations:Array<
    {
      sprite:FunkinSprite,
      delay:Float
    }> = [];

    var playerCharacterId:Null<String>;
    var playerCharacter:Null<PlayableCharacter>;

    var introMusicAudio:Null<FunkinSound>;
  
    var rankBg:FunkinSprite;
    var cameraBG:FunkinCamera;
    var cameraScroll:FunkinCamera;
    var cameraEverything:FunkinCamera;

    var folder:String = "menus/base/resultScreen";
    public function new(params:ResultsStateParams)
    {
        super();

        this.params = params;
    
        rank = params.validScore ? Scoring.calculateRank(params.scoreData) : SHIT;

        cameraBG = cameraScroll = cameraEverything = new FunkinCamera();
        
        var fontLetters:String = "AaBbCcDdEeFfGgHhiIJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890";
        songName = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image('$folder/tardlingSpritesheet'), fontLetters, FlxPoint.get(49, 62)));
        songName.text = params.title;
        songName.letterSpacing = -15;
        songName.angle = -4.4;
        songName.zIndex = 1000;
    
        difficulty = new FunkinSprite(555).loadImage('$folder/difficulties/${params?.difficultyId ?? 'normal'}');
        difficulty.zIndex = 1000;
    
        clearPercentSmall = new ClearPercentCounter(FlxG.width / 2 + 300, FlxG.height / 2 - 100, 100, true);
        clearPercentSmall.zIndex = 1000;
        clearPercentSmall.visible = false;

        bgFlash = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFFF1A6, 0xFFFFF1BE], 90);

        resultsAnim = new FunkinSprite(-200, -10).loadFrame('$folder/results');
        ratingsPopin = new FunkinSprite(-135, 135).loadFrame('$folder/ratingsPopin');
        scorePopin = new FunkinSprite(-180, 515).loadFrame('$folder/scorePopin');
        highscoreNew = new FunkinSprite(44, 557).loadFrame('$folder/highscoreNew');


        playerCharacterId = PlayerRegistry.instance.getCharacterOwnerId(params.characterId);
        playerCharacter = PlayerRegistry.instance.fetchEntry(playerCharacterId ?? 'bf');
        var styleData = FreeplayStyleRegistry.instance.fetchEntry(playerCharacter.getFreeplayStyleID());

        score = new ResultScore(35, 305, 10, params.scoreData.score, styleData ?? null);
        rankBg = new FunkinSprite().makeSolidColor(FlxG.width, FlxG.height, 0xFF000000);
    }

    override function create():Void
    {
        if (FlxG.sound.music != null) FlxG.sound.music.stop();
        cameraScroll.angle = -3.8;
    
        cameraBG.bgColor = FlxColor.MAGENTA;
        cameraScroll.bgColor = cameraEverything.bgColor = FlxColor.TRANSPARENT;
    
        FlxG.cameras.add(cameraBG, false);
        FlxG.cameras.add(cameraScroll, false);
        FlxG.cameras.add(cameraEverything, false);

        FlxG.cameras.setDefaultDrawTarget(cameraEverything, true);
        this.camera = cameraEverything;
    
        FlxG.camera.zoom = 1.0;

        var bg:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECC5C, 0xFFFDC05C], 90);
        bg.scrollFactor.set();
        bg.zIndex = 10;
        bg.camera = cameraBG;
        add(bg);

        bgFlash.scrollFactor.set();
        bgFlash.visible = false;
        bgFlash.zIndex = 20;
        add(bgFlash);

        var soundSystem:FunkinSprite = new FunkinSprite(-15, -180).loadFrame('$folder/soundSystem');
        soundSystem.animation.addByPrefix("idle", "sound system", 24, false);
        soundSystem.visible = false;
        new FlxTimer().start(8 / 24, _ -> {
          soundSystem.animation.play("idle");
          soundSystem.visible = true;
        });
        soundSystem.zIndex = 1100;
        add(soundSystem);

        var playerAnimationDatas:Array<PlayerResultsAnimationData> = playerCharacter != null ? playerCharacter.getResultsAnimationDatas(rank) : [];
        for (animData in playerAnimationDatas)
        {
            if (animData == null) continue;

            var animPath:String = Paths.stripLibrary(animData.assetPath);
            var offsets = animData.offsets ?? [0, 0];
            if(animData.renderType != 'animate')
            {
                var animation:FunkinSprite = new FunkinSprite(offsets[0], offsets[1]).loadFrame(animPath);
                animation.animation.addByPrefix('idle', '', 24, false, false, false);
                if (animData.loopFrame != null)
                {
                    animation.animation.finishCallback = (_name:String) -> {
                        if (animation != null) animation.animation.play('idle', true, false, animData.loopFrame ?? 0);
                    }
                }
                animation.visible = false;
                characterSparrowAnimations.push({
                    sprite: animation,
                    delay: animData.delay ?? 0.0
                });
                add(animation);
            }
            else
            {
                var animation:FlxAtlasSprite = new FlxAtlasSprite(offsets[0], offsets[1], Paths.animateAtlas(animPath));
                animation.zIndex = animData.zIndex ?? 500;
                animation.scale.set(animData.scale ?? 1.0, animData.scale ?? 1.0);
                if (!(animData.looped ?? true))
                {
                    animation.onAnimationComplete.add((_name:String) -> {
                        if (animation != null) animation.anim.pause();
                    });
                }
                else if (animData.loopFrameLabel != null)
                {
                    animation.onAnimationComplete.add((_name:String) -> {
                        if (animation != null)  animation.playAnimation(animData.loopFrameLabel ?? '', true, false, true); 
                    });
                }
                else if (animData.loopFrame != null)
                {
                    animation.onAnimationComplete.add((_name:String) -> {
                        if (animation != null)
                        {
                            animation.anim.curFrame = animData.loopFrame ?? 0;
                            animation.anim.play(); // unpauses this anim, since it's on PlayOnce!
                        }
                    });
                }
                animation.visible = false;
                characterAtlasAnimations.push({
                    sprite: animation,
                    delay: animData.delay ?? 0.0,
                    forceLoop: (animData.loopFrame ?? -1) == 0
                });
                add(animation);
            }
        }
        add(difficulty);
    
        add(songName);

        var angleRad = songName.angle * Math.PI / 180;
        speedOfTween.x = -1.0 * Math.cos(angleRad);
        speedOfTween.y = -1.0 * Math.sin(angleRad);
    
        timerThenSongName(1.0, false);

        songName.shader = maskShaderSongName;
        difficulty.shader = maskShaderDifficulty;

        maskShaderDifficulty.swagMaskX = difficulty.x - 15;

        var blackTopBar:FunkinSprite = new FunkinSprite().loadImage('$folder/topBarBlack');
        blackTopBar.y = -blackTopBar.height;
        FlxTween.tween(blackTopBar, {y: 0}, 7 / 24, {ease: FlxEase.quartOut, startDelay: 3 / 24});
        blackTopBar.zIndex = 1010;
        add(blackTopBar);

        resultsAnim.animation.addByPrefix("result", "results instance 1", 24, false);
        resultsAnim.visible = false;
        resultsAnim.zIndex = 1200;
        add(resultsAnim);
        new FlxTimer().start(6 / 24, _ -> {
            resultsAnim.visible = true;
            resultsAnim.animation.play("result");
        });

        ratingsPopin.animation.addByPrefix("idle", "Categories", 24, false);
        ratingsPopin.visible = false;
        ratingsPopin.zIndex = 1200;
        add(ratingsPopin);
        new FlxTimer().start(21 / 24, _ -> {
            ratingsPopin.visible = true;
            ratingsPopin.animation.play("idle");
        });

        scorePopin.animation.addByPrefix("score", "tally score", 24, false);
        scorePopin.visible = false;
        scorePopin.zIndex = 1200;
        add(scorePopin);
        new FlxTimer().start(36 / 24, _ -> {
            scorePopin.visible = true;
            scorePopin.animation.play("score");
        });

        new FlxTimer().start(37 / 24, _ -> {
            score.visible = true;
            score.animateNumbers();
            startRankTallySequence();
        });

        new FlxTimer().start(rank.getBFDelay(), _ -> {
            afterRankTallySequence();
        });
      
        new FlxTimer().start(rank.getFlashDelay(), _ -> {
            displayRankText();
        });

        highscoreNew.animation.addByPrefix("new", "highscoreAnim0", 24, false);
        highscoreNew.visible = false;
        highscoreNew.updateHitbox();
        highscoreNew.zIndex = 1200;
        add(highscoreNew);

        new FlxTimer().start(rank.getHighscoreDelay(), _ -> {
            if (params.isNewHighscore ?? false)
            {
                highscoreNew.visible = true;
                highscoreNew.animation.play("new");
                highscoreNew.animation.finishCallback = _ -> highscoreNew.animation.play("new", true, false, 16);
            }
            else
                highscoreNew.visible = false;
        });

        var hStuf:Int = 50;

        var ratingGrp:FlxTypedGroup<TallyCounter> = new FlxTypedGroup<TallyCounter>();
        ratingGrp.zIndex = 1200;
        add(ratingGrp);

        var totalHit:TallyCounter = new TallyCounter(375, hStuf * 3, params.scoreData.tallies.totalNotesHit);
        ratingGrp.add(totalHit);
    
        var maxCombo:TallyCounter = new TallyCounter(375, hStuf * 4, params.scoreData.tallies.maxCombo);
        ratingGrp.add(maxCombo);
    
        hStuf += 2;
        var extraYOffset:Float = 7;
    
        hStuf += 2;

        var tallySick:TallyCounter = new TallyCounter(230, (hStuf * 5) + extraYOffset, params.scoreData.tallies.sick, 0xFF89E59E);
        ratingGrp.add(tallySick);
    
        var tallyGood:TallyCounter = new TallyCounter(210, (hStuf * 6) + extraYOffset, params.scoreData.tallies.good, 0xFF89C9E5);
        ratingGrp.add(tallyGood);
    
        var tallyBad:TallyCounter = new TallyCounter(190, (hStuf * 7) + extraYOffset, params.scoreData.tallies.bad, 0xFFE6CF8A);
        ratingGrp.add(tallyBad);
    
        var tallyShit:TallyCounter = new TallyCounter(220, (hStuf * 8) + extraYOffset, params.scoreData.tallies.shit, 0xFFE68C8A);
        ratingGrp.add(tallyShit);
    
        var tallyMissed:TallyCounter = new TallyCounter(260, (hStuf * 9) + extraYOffset, params.scoreData.tallies.missed, 0xFFC68AE6);
        ratingGrp.add(tallyMissed);

        score.visible = false;
        score.zIndex = 1200;
        add(score);    

        for (ind => rating in ratingGrp.members)
        {
            rating.visible = false;
            new FlxTimer().start((0.3 * ind) + 1.20, _ -> {
                rating.visible = true;
                FlxTween.tween(rating, {curNumber: rating.neededNumber}, 0.5, {ease: FlxEase.quartOut});
            });
        }

        new FlxTimer().start(rank.getMusicDelay(), _ -> {
            var introMusic:String = Paths.music('results/${getMusicPath(playerCharacter, rank)}-intro');
            if (Paths.exists(introMusic))
            {
                introMusicAudio = FunkinSound.load(introMusic, 1.0, false, true, true, () -> {
                    introMusicAudio = null;
                    FunkinSound.playMusic('results/${getMusicPath(playerCharacter, rank)}',
                    {
                        startingVolume: 1.0,
                        overrideExisting: true,
                        restartTrack: true
                    });
                });
            }
            else
            {
                FunkinSound.playMusic('results/${getMusicPath(playerCharacter, rank)}',
                {
                    startingVolume: 1.0,
                    overrideExisting: true,
                    restartTrack: true
                });
            }
        });

        rankBg.zIndex = 99999;
        add(rankBg);
    
        rankBg.alpha = 0;
    
        refresh();
    
        super.create();
    }

    function getMusicPath(player:Null<PlayableCharacter>, rank:ScoringRank):String 
        return player?.getResultsMusicPath(rank) ?? 'normal';

    var rankTallyTimer:Null<FlxTimer> = null;
    var clearPercentTarget:Int = 100;
    var clearPercentLerp:Int = 0;
  
    function startRankTallySequence():Void
    {
        bgFlash.visible = true;
        FlxTween.tween(bgFlash, {alpha: 0}, 5 / 24);
        // NOTE: Only divide if totalNotes > 0 to prevent divide-by-zero errors.
        var clearPercentFloat = params.scoreData.tallies.totalNotes == 0 ? 0.0 : (params.scoreData.tallies.sick +
          params.scoreData.tallies.good) / params.scoreData.tallies.totalNotes * 100;
        clearPercentTarget = Math.floor(clearPercentFloat);

        clearPercentLerp = Std.int(Math.max(0, clearPercentTarget - 36));

        trace('Clear percent target: ' + clearPercentFloat + ', round: ' + clearPercentTarget);
    
        var clearPercentCounter:ClearPercentCounter = new ClearPercentCounter(FlxG.width / 2 + 190, FlxG.height / 2 - 70, clearPercentLerp);
        FlxTween.tween(clearPercentCounter, {curNumber: clearPercentTarget}, 58 / 24,{
            ease: FlxEase.quartOut,
            onUpdate: _ -> {
                clearPercentLerp = Math.round(clearPercentLerp);
                clearPercentCounter.curNumber = Math.round(clearPercentCounter.curNumber);
                // Only play the tick sound if the number increased.
                if (clearPercentLerp != clearPercentCounter.curNumber)
                {
                    trace('$clearPercentLerp and ${clearPercentCounter.curNumber}');
                    clearPercentLerp = clearPercentCounter.curNumber;
                    FunkinSound.playOnce(Paths.sound('scrollMenu'));
                }
            },
            onComplete: _ -> {
                FunkinSound.playOnce(Paths.sound('confirmMenu'));
                clearPercentCounter.curNumber = clearPercentTarget;               

                clearPercentCounter.flash(true);
                new FlxTimer().start(0.4, _ -> {
                  clearPercentCounter.flash(false);
                });

                new FlxTimer().start(0.25, _ -> {
                    FlxTween.tween(clearPercentCounter, {alpha: 0}, 0.5,{
                        startDelay: 0.5,
                        ease: FlxEase.quartOut,
                        onComplete: _ -> {
                          remove(clearPercentCounter);
                        }
                    });
                });
            }
        });
        clearPercentCounter.zIndex = 450;
        add(clearPercentCounter);

        if (ratingsPopin != null)
        {
            ratingsPopin.animation.finishCallback = _ -> {
                highscoreNew.visible = params.isNewHighscore ?? false;
                highscoreNew.animation.play("new");
            };
        }
        refresh();
    }

    function displayRankText():Void
    {
        bgFlash.visible = true;
        bgFlash.alpha = 1;
        FlxTween.tween(bgFlash, {alpha: 0}, 14 / 24);
    
        var rankTextVert:FlxBackdrop = new FlxBackdrop(Paths.image(rank.getVerTextAsset()), Y, 0, 30);
        rankTextVert.x = FlxG.width - 44;
        rankTextVert.y = 100;
        rankTextVert.zIndex = 990;
        add(rankTextVert);
    
        FlxFlicker.flicker(rankTextVert, 2 / 24 * 3, 2 / 24, true);

        new FlxTimer().start(30 / 24, _ -> {
            rankTextVert.velocity.y = -80;
        });

        for (i in 0...12)
        {
            var rankTextBack:FlxBackdrop = new FlxBackdrop(Paths.image(rank.getHorTextAsset()), X, 10, 0);
            rankTextBack.x = FlxG.width / 2 - 320;
            rankTextBack.y = 50 + (135 * i / 2) + 10;
            // rankTextBack.angle = -3.8;
            rankTextBack.zIndex = 100;
            rankTextBack.cameras = [cameraScroll];
            add(rankTextBack);
      
            // Scrolling.
            rankTextBack.velocity.x = (i % 2 == 0) ? -7.0 : 7.0;
        }

        refresh();
    }

    function afterRankTallySequence():Void
    {
        showSmallClearPercent();

        for (atlas in characterAtlasAnimations)
        {
            new FlxTimer().start(atlas.delay, _ -> {
                if (atlas.sprite == null) return;
                atlas.sprite.visible = true;
                atlas.sprite.playAnimation('');
            });
        }

        for (sprite in characterSparrowAnimations)
        {
            new FlxTimer().start(sprite.delay, _ -> {
                if (sprite.sprite == null) return;
                sprite.sprite.visible = true;
                sprite.sprite.animation.play('idle', true);
            });
        }        
    }

    function timerThenSongName(timerLength:Float = 3.0, autoScroll:Bool = true):Void
    {
        movingSongStuff = false;

        difficulty.x = 555;
    
        var diffYTween:Float = 122;
    
        difficulty.y = -difficulty.height;
        FlxTween.tween(difficulty, {y: diffYTween}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.8});
        if (clearPercentSmall != null)
        {
            clearPercentSmall.x = (difficulty.x + difficulty.width) + 60;
            clearPercentSmall.y = -clearPercentSmall.height;
            FlxTween.tween(clearPercentSmall, {y: 122 - 5}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.85});
        }

        songName.y = -songName.height;
        var fuckedupnumber = (10) * (songName.text.length / 15);
        FlxTween.tween(songName, {y: diffYTween - 25 - fuckedupnumber}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.9});
        songName.x = clearPercentSmall.x + 94;

        new FlxTimer().start(timerLength, _ -> {
            var tempSpeed = FlxPoint.get(speedOfTween.x, speedOfTween.y);

            speedOfTween.set(0, 0);
            FlxTween.tween(speedOfTween, {x: tempSpeed.x, y: tempSpeed.y}, 0.7, {ease: FlxEase.quadIn});
      
            movingSongStuff = (autoScroll);
        });
    }

    function showSmallClearPercent():Void
    {
        if (clearPercentSmall != null)
        {
            add(clearPercentSmall);
            clearPercentSmall.visible = true;
            clearPercentSmall.flash(true);
            new FlxTimer().start(0.4, _ -> {
              clearPercentSmall.flash(false);
            });
      
            clearPercentSmall.curNumber = clearPercentTarget;
            clearPercentSmall.zIndex = 1000;
            refresh();
        }

        new FlxTimer().start(2.5, _ -> {
            movingSongStuff = true;
        });
    }

    var movingSongStuff:Bool = false;
    var speedOfTween:FlxPoint = FlxPoint.get(-1, 1);
  
    override function draw():Void
    {
        super.draw();

        songName.clipRect = FlxRect.get(Math.max(0, 520 - songName.x), 0, FlxG.width, songName.height);
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        maskShaderDifficulty.swagSprX = difficulty.x;

        if (movingSongStuff)
        {
            songName.x += speedOfTween.x;
            difficulty.x += speedOfTween.x;
            clearPercentSmall.x += speedOfTween.x;
            songName.y += speedOfTween.y;
            difficulty.y += speedOfTween.y;
            clearPercentSmall.y += speedOfTween.y;
            if (songName.x + songName.width < 100) timerThenSongName();
        }

        if (FlxG.keys.justPressed.RIGHT) speedOfTween.x += 0.1;

        if (FlxG.keys.justPressed.LEFT)  speedOfTween.x -= 0.1;

        if (controls.PAUSE)
        {
            if (introMusicAudio != null) 
            {
                introMusicAudio.onComplete = null;

                FlxTween.tween(introMusicAudio, {volume: 0}, 0.8, {
                    onComplete: _ -> {
                        if (introMusicAudio != null) {
                          introMusicAudio.stop();
                          introMusicAudio.destroy();
                          introMusicAudio = null;
                        }
                    }
                });

                FlxTween.tween(introMusicAudio, {pitch: 3}, 0.1,{
                    onComplete: _ -> {
                        FlxTween.tween(introMusicAudio, {pitch: 0.5}, 0.4);
                    }
                });
            }
            else if (FlxG.sound.music != null)
            {
                FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.8, {
                    onComplete: _ -> {
                      FlxG.sound.music.stop();
                      FlxG.sound.music.destroy();
                    }
                });
                FlxTween.tween(FlxG.sound.music, {pitch: 3}, 0.1,{
                    onComplete: _ -> {
                        FlxTween.tween(FlxG.sound.music, {pitch: 0.5}, 0.4);
                    }
                });
            }

            var targetState:flixel.FlxState = new MainMenuState();
            var shouldTween = false;
            var shouldUseSubstate = false;
      
            if (params.storyMode)
            {
                shouldTween = false;
                shouldUseSubstate = true;
                targetState = new StickerSubState(null, (sticker) -> new StoryMenuState(sticker));
            }
            else
            {
                if (rank > Scoring.calculateRank(params?.prevScoreData))
                {
                    trace('THE RANK IS Higher.....');
    
                    shouldTween = true;
                    targetState = FreeplayState.build({
                        character: playerCharacterId ?? "bf",
                        fromResults:
                        {
                            oldRank: Scoring.calculateRank(params?.prevScoreData),
                            newRank: rank,
                            songId: params.songId,
                            difficultyId: params.difficultyId,
                            playRankAnim: true
                        }
                    });
                }
                else
                {
                    shouldTween = false;
                    shouldUseSubstate = true;
                    targetState = new StickerSubState(null, (sticker) -> FreeplayState.build(null, sticker));
                }
            }
    
            if (shouldTween)
            {
                FlxTween.tween(rankBg, {alpha: 1}, 0.5,{
                    ease: FlxEase.expoOut,
                    onComplete: function(_) {
                        if (shouldUseSubstate && targetState is FlxSubState)
                            openSubState(cast targetState);
                        else
                            FlxG.switchState(targetState);
                    }
                });
            }
            else
            {
                if (shouldUseSubstate && targetState is FlxSubState)
                    openSubState(cast targetState);
                else
                    FlxG.switchState(targetState);
            }


            //Idk Result Score after you put score it ok then :/
            PlayState.instance.songScore = 0;
			Highscore.instance.resetTallies();
			Timings.callAccuracy();
			Timings.updateAccuracy(0);
        }
    }
}

typedef ResultsStateParams = {
    var storyMode:Bool;
    var title:String;
    var songId:String;
    var ?characterId:String;
    var ?isNewHighscore:Bool;
    var ?difficultyId:String;
    var scoreData:SaveScoreData;
    var ?prevScoreData:SaveScoreData;
    var ?validScore:Bool;
}