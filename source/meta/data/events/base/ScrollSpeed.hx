package meta.data.events.base;

class ScrollSpeedEvent extends SongEvent
{
    public function new()
    {
        super('ScrollSpeed');
    }

    public override function handleEvent(data:SongEventData)
    {
        if (PlayState.instance == null) return;

        var scroll:Float = data.getFloat('scroll') ?? 1;
        var duration:Float = data.getFloat('duration') ?? 4.0;
        var ease:String = data.getString('ease') ?? 'linear';
        var strumline:Int = data.getInt('strumline') ?? 0;
        var absolute:Bool = data.getBool('absolute') ?? false;

        if (!absolute) scroll = scroll * (PlayState.instance?.currentChart?.scrollSpeed ?? 1.0);

        switch (ease)
        {
            case 'INSTANT':
                PlayState.instance.tweenScrollSpeed(scroll, 0, null, strumline);
            default:
                var durSeconds = Conductor.instance.stepLengthMs * duration / 1000;
                var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, ease);
                if (easeFunction == null)
                {
                  trace('Invalid ease function: $ease');
                  return;
                }
        
                PlayState.instance.tweenScrollSpeed(scroll, durSeconds, easeFunction, strumline);
        }
    }

    public override function getTitle():String return 'Scroll Speed';

    public override function getEventSchema():SongEventSchema
    {
        return new SongEventSchema([
            {
                name: 'scroll',
                title: 'Target Value',
                defaultValue: 1.0,
                step: 0.1,
                type: SongEventFieldType.FLOAT,
                units: 'x'
            },
            {
                name: 'duration',
                title: 'Duration',
                defaultValue: 4.0,
                step: 0.5,
                type: SongEventFieldType.FLOAT,
                units: 'steps'
            },
            {
                name: 'ease',
                title: 'Easing Type',
                defaultValue: 'linear',
                type: SongEventFieldType.ENUM,
                keys: [
                  'Linear' => 'linear',
                  'Instant (Ignores Duration)' => 'INSTANT',
                  'Sine In' => 'sineIn',
                  'Sine Out' => 'sineOut',
                  'Sine In/Out' => 'sineInOut',
                  'Quad In' => 'quadIn',
                  'Quad Out' => 'quadOut',
                  'Quad In/Out' => 'quadInOut',
                  'Cube In' => 'cubeIn',
                  'Cube Out' => 'cubeOut',
                  'Cube In/Out' => 'cubeInOut',
                  'Quart In' => 'quartIn',
                  'Quart Out' => 'quartOut',
                  'Quart In/Out' => 'quartInOut',
                  'Quint In' => 'quintIn',
                  'Quint Out' => 'quintOut',
                  'Quint In/Out' => 'quintInOut',
                  'Expo In' => 'expoIn',
                  'Expo Out' => 'expoOut',
                  'Expo In/Out' => 'expoInOut',
                  'Smooth Step In' => 'smoothStepIn',
                  'Smooth Step Out' => 'smoothStepOut',
                  'Smooth Step In/Out' => 'smoothStepInOut',
                  'Elastic In' => 'elasticIn',
                  'Elastic Out' => 'elasticOut',
                  'Elastic In/Out' => 'elasticInOut'
                ]
            },
            {
                name: 'strumline',
                title: 'Target Strumline',
                defaultValue: 0,
                step: 1,
                type: SongEventFieldType.INTEGER
            },
            {
                name: 'absolute',
                title: 'Absolute',
                defaultValue: false,
                type: SongEventFieldType.BOOL,
            }
        ]);
    }
}