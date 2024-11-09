package gameObjects.userInterface.menu.freeplay;

class CapsuleOptionsMenu extends FlxSpriteGroup
{
    var capsuleMenuBG:FlxSprite;
    var queueDestroy:Bool = false;
  
    var instrumentalIds:Array<String> = [''];
    var currentInstrumentalIndex:Int = 0;
  
    var currentInstrumental:FlxText;
    var folder:String = "menus/base/freeplay";
    public function new(x:Float = 0, y:Float = 0, instIds:Array<String>):Void
    {
        super(x, y);

        this.instrumentalIds = instIds;

        capsuleMenuBG = new FlxSprite();
        capsuleMenuBG.frames = Paths.getSparrowAtlas('$folder/instBox');
        capsuleMenuBG.animation.addByPrefix('open', 'open0', 24, false);
        capsuleMenuBG.animation.addByPrefix('idle', 'idle0', 24, true);
        capsuleMenuBG.animation.addByPrefix('open', 'open0', 24, false);
    
        currentInstrumental = new FlxText(0, 36, capsuleMenuBG.width, '');
        currentInstrumental.setFormat('VCR OSD Mono', 40, FlxTextAlign.CENTER, true);

        final PAD = 4;
        var leftArrow = new InstrumentalSelector(PAD, 30, false, FreeplayState.instance.getControls());
        var rightArrow = new InstrumentalSelector(capsuleMenuBG.width - leftArrow.width - PAD, 30, true, FreeplayState.instance.getControls());
    
        var label:FlxText = new FlxText(0, 5, capsuleMenuBG.width, 'INSTRUMENTAL');
        label.setFormat('VCR OSD Mono', 24, FlxTextAlign.CENTER, true);

        add(capsuleMenuBG);
        add(leftArrow);
        add(rightArrow);
        add(label);
        add(currentInstrumental);
    
        capsuleMenuBG.animation.finishCallback = function(_) {
          capsuleMenuBG.animation.play('idle', true);
        };
        capsuleMenuBG.animation.play('open', true);        
    }

    public override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (FreeplayState.instance.getControls().BACK)
        {
            close();
            return;
        }

        var changedInst = false;
        if (FreeplayState.instance.getControls().UI_LEFT_P || FreeplayState.instance.getControls().UI_RIGHT_P)
        {
            currentInstrumentalIndex = (FreeplayState.instance.getControls().UI_LEFT_P ? currentInstrumentalIndex + 1 : currentInstrumentalIndex - 1) % instrumentalIds.length;
            changedInst = true;
        }

        if (!changedInst && currentInstrumental.text == '') changedInst = true;

        if (changedInst)
        {
            currentInstrumental.text = instrumentalIds[currentInstrumentalIndex].toTitleCase() ?? '';
            if (currentInstrumental.text == '') currentInstrumental.text = 'Default';
        }

        if (FreeplayState.instance.getControls().ACCEPT) onConfirm(instrumentalIds[currentInstrumentalIndex] ?? '');

        if (queueDestroy)
        {
            destroy();
            return;
        }
    }

    public function close():Void
    {
        capsuleMenuBG.animation.play('open', true, true);
        capsuleMenuBG.animation.finishCallback = function(_) {
            queueDestroy = true;
        };
    }

    public dynamic function onConfirm(targetInstId:String):Void
        throw 'onConfirm not implemented!';

}

class InstrumentalSelector extends FlxSprite
{
    var controls:Controls;
    var whiteShader:PureColor;
    var baseScale:Float = 0.6;

    public function new(x:Float, y:Float, flipped:Bool, controls:Controls)
    {
        super(x, y);
    
        this.controls = controls;
        
        frames = Paths.getSparrowAtlas('menus/base/freeplay/freeplaySelector');
        animation.addByPrefix('shine', 'arrow pointer loop', 24);
        animation.play('shine');
    
        whiteShader = new PureColor(FlxColor.WHITE);
    
        shader = whiteShader;
    
        flipX = flipped;
    
        scale.x = scale.y = 1 * baseScale;
        updateHitbox();
    }

    override function update(elapsed:Float):Void
    {
        if (flipX && controls.UI_RIGHT_P) moveShitDown();
        if (!flipX && controls.UI_LEFT_P) moveShitDown();
    
        super.update(elapsed);
    }

    function moveShitDown():Void
    {
        offset.y -= 5;

        whiteShader.colorSet = true;
    
        scale.x = scale.y = 0.5 * baseScale;
    
        new FlxTimer().start(2 / 24, function(tmr) {
          scale.x = scale.y = 1 * baseScale;
          whiteShader.colorSet = false;
          updateHitbox();
        });
    }
}