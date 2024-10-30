package meta.data.events.base;

class PlayAnimation extends SongEvent
{
    public function new()
    {
        super('PlayAnimation');
    }

    public override function handleEvent(data:SongEventData)
    {
        if (PlayState.isNull()) return;

        var targetName = data.getString('target');
        var anim = data.getString('anim');
        var force = data.getBool('force');
        if (force == null) force = false;
    
        var target:FlxSprite = null;

        switch (targetName)
        {
            case 'boyfriend' | 'bf' | 'player':
                trace('Playing animation $anim on boyfriend.');
                target = PlayState.instance.boyfriend;
            case 'dad' | 'opponent':
                trace('Playing animation $anim on dad.');
                target = PlayState.instance.dad;
            case 'girlfriend' | 'gf':
                trace('Playing animation $anim on girlfriend.');
                target = PlayState.instance.gf;
            default:
                target = PlayState.instance.stage.getNamedProp(targetName);
                if (target == null) 
                    trace('Unknown animation target: $targetName');
                else
                  trace('Fetched animation target $targetName from stage.');
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

    public override function getTitle():String return "Play Animation";

    public override function getEventSchema():SongEventSchema
    {
        return new SongEventSchema([
            {
                name: 'target',
                title: 'Target',
                type: SongEventFieldType.STRING,
                defaultValue: 'boyfriend',
            },
            {
                name: 'anim',
                title: 'Animation',
                type: SongEventFieldType.STRING,
                defaultValue: 'idle',
            },
            {
                name: 'force',
                title: 'Force',
                type: SongEventFieldType.BOOL,
                defaultValue: false
            }
        ]);
    }
}