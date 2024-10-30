package meta.data.events.base;

class ZoomCamera extends SongEvent
{
    public function new()
    {
        super('ZoomCamera');
    }

    public override function handleEvent(data:SongEventData)
    {
        if (PlayState.isNull()) return;

        var zoom:Float = data.getFloat('zoom') ?? 1;
        var duration:Float = data.getFloat('duration') ?? 3;
        var mode:String = data.getString('mode') ?? 'direct';
        var isDirectMode:Bool = mode == 'direct';
        var ease:String = data.getString('ease') ?? 'linear';

        switch (ease)
        {
            case 'INSTANT':
                PlayState.instance.tweenCameraZoom(zoom, 0, isDirectMode);
            default:
                var durSeconds = Conductor.instance.stepLengthMs * duration / 1000;
                var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, ease);
                if (easeFunction == null)
                {
                    trace('Invalid ease function: $ease');
                    return;
                }
        
            PlayState.instance.tweenCameraZoom(zoom, durSeconds, isDirectMode, easeFunction);
        }
    }

    public override function getTitle():String return 'Zoom Camera';

    public override function getEventSchema():SongEventSchema
    {
        return new SongEventSchema([
            {
              name: 'zoom',
              title: 'Zoom Level',
              defaultValue: 1.0,
              step: 0.05,
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
              name: 'mode',
              title: 'Mode',
              defaultValue: 'stage',
              type: SongEventFieldType.ENUM,
              keys: ['Stage zoom' => 'stage', 'Absolute zoom' => 'direct']
            },
            {
              name: 'ease',
              title: 'Easing Type',
              defaultValue: 'linear',
              type: SongEventFieldType.ENUM,
              keys: [
                'Linear' => 'linear',
                'Instant' => 'INSTANT',
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
            }
        ]);
    }
}