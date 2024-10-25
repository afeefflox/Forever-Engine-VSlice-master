package meta.data.events.base;

class ScrollSpeed extends Events
{
    public function new()
    {
        super('Scroll Speed');
        this.values = [
           1,
           4,
           [
            //entire FlxEase List
            'instant',
            'linear',
            'sineIn',
            'sineOut',
            'sineInOut',
            'quadIn',
            'quadOut',
            'quadInOut',
            'cubeIn',
            'cubeOut',
            'cubeInOut',
            'quartIn',
            'quartOut',
            'quartInOut',
            'quintIn',
            'quintOut',
            'quintInOut',
            'expoIn',
            'expoOut',
            'expoInOut',
            'smoothStepIn',
            'smoothStepOut',
            'smoothStepInOut',
            'elasticIn',
            'elasticOut',
            'elasticInOut',
           ],
           [ 
            'boyfriend',
            'dad',
            'both'
           ],
           false
        ];
    }

    override function returnDescription():String
    {
        return 'Speed CHART MODE \nValue 1: Scroll \nValue 2: Durations \nValue 3: Ease \nValue 4: Strumline Target \nValue 5: Absolute (Multiplicative Scroll enabled?)';
    }

    override function initFunction(params:Array<Dynamic>)
    {
        super.initFunction(params);

        var strumlineNames:Array<String> = [];
        var scroll:Float = Std.parseFloat(params[0]);
        var absolute:Bool = params[4];

        if (!absolute)  scroll = scroll * (PlayState?.SONG?.speed ?? 1.0);

        switch (params[3])
        {
            case 'both':
                strumlineNames = ['plrStrums', 'cpuStrums'];
            case 'boyfriend':
                strumlineNames = ['plrStrums'];
            case 'dad':
                strumlineNames = ['cpuStrums'];
        }

        switch (params[2])
        {
            case 'instant':
                PlayState.instance.tweenScrollSpeed(scroll, 0, null, strumlineNames);
            default:
                var durSeconds = Conductor.stepCrochet * params[1] / 1000;
                var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, params[2]);
                if (easeFunction == null)
                {
                  trace('Invalid ease function: ${params[2]}');
                  return;
                }
                PlayState.instance.tweenScrollSpeed(scroll, durSeconds, easeFunction, strumlineNames);
        }
    }
}