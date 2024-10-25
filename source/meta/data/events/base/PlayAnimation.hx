package meta.data.events.base;

//now Move in Built in Game cuz I think it better
class PlayAnimation extends Events
{
    public function new()
    {
        super('Play Animation');
        this.values = [
            "bf",
            "hey",
            true
        ];
    }

    override function returnDescription():String
    {
        return 'Basically Play Animation during Mid Song \nValue 1: Character or Props \nValue 2: Animation Name \nValue 3: Force Animation';
    }

    override function initFunction(params:Array<Dynamic>)
    {
        super.initFunction(params);
        if(PlayState.isNull()) return;

        var target:FlxSprite = null;

        var anim = params[1];
        var force = params[2];
        if (force == null) force = false;        

        switch (params[0])
        {
            case 'bf':
                target = PlayState.instance.boyfriend;
            case 'dad':
                target = PlayState.instance.dad;
            case 'gf':
                target = PlayState.instance.gf;
            default:
                target = PlayState.instance.stage.getNamedProp(params[0]);
        }

        if (target != null)
        {
            if (Std.isOfType(target, BaseCharacter))
            {
                var targetChar:BaseCharacter = cast target;
                targetChar.playAnim(anim, force, force);
            }
            else
                target.animation.play(anim, force);
        }
    }
}