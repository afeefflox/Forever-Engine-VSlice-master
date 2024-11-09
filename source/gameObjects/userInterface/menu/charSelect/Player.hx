package gameObjects.userInterface.menu.charSelect;

class Player extends FlxAtlasSprite implements IBPMSyncedScriptedClass
{
    var folder:String = "menus/base/charSelect/chill";
    public function new(x:Float, y:Float)
    {
        super(x, y, Paths.animateAtlas('$folder/bf'));

        onAnimationComplete.add(function(animLabel:String) {
            switch (animLabel)
            {
              case "slidein":
                if (hasAnimation("slidein idle point"))
                {
                  playAnimation("slidein idle point", true, false, false);
                }
                else
                {
                  playAnimation("idle", true, false, false);
                }
              case "deselect":
                playAnimation("deselect loop start", true, false, true);
      
              case "slidein idle point", "cannot select Label", "unlock":
                playAnimation("idle", true, false, false);
              case "idle":
                trace('Waiting for onBeatHit');
            }
        });
    }

    public function onStepHit(event:SongTimeScriptEvent):Void {}

    public function onBeatHit(event:SongTimeScriptEvent):Void
    {
        if (getCurrentAnimation() == "idle") playAnimation("idle", true, false, false);
    }

    public function switchChar(str:String)
    {
        loadAtlas(Paths.animateAtlas('$folder/$str'));
        playAnimation("slidein", true, false, false);
        updateHitbox();
    }

    public function onScriptEvent(event:ScriptEvent):Void {};
    public function onCreate(event:ScriptEvent):Void {};
    public function onDestroy(event:ScriptEvent):Void {};
    public function onUpdate(event:UpdateScriptEvent):Void {};
}