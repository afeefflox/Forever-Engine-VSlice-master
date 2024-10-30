package meta.data.events.base;

class FocusCamera extends SongEvent
{
    public function new() 
    {
        super('FocusCamera');
    }

    public override function handleEvent(data:SongEventData)
    {
        if (PlayState.isNull()) return;

        var posX:Null<Float> = data.getFloat('x');
        if (posX == null) posX = 0.0;
        var posY:Null<Float> = data.getFloat('y');
        if (posY == null) posY = 0.0;
    
        var char:Null<Int> = data.getInt('char');
    
        if (char == null) char = cast data.value;
    
        var duration:Null<Float> = data.getFloat('duration');
        if (duration == null) duration = 4.0;
        var ease:Null<String> = data.getString('ease');
        if (ease == null) ease = 'CLASSIC';

        var targetX:Float = posX;
        var targetY:Float = posY;
        var instance = PlayState.instance;
        switch (char)
        {
            case -1:
                trace('Focusing camera on static position.');
            case 0:
                var bfPoint = instance.boyfriend.cameraFocusPoint;
                targetX += bfPoint.x;
                targetY += bfPoint.y;
            case 1:
                var dadPoint = instance.dad.cameraFocusPoint;
                targetX += dadPoint.x;
                targetY += dadPoint.y;
            case 2:
                var gfPoint = instance.gf.cameraFocusPoint;
                targetX += gfPoint.x;
                targetY += gfPoint.y;
            default:
                trace('Unknown camera focus: ' + data);
        }

        switch (ease)
        {
            case "CLASSIC":
                instance.resetCamera(false, false, false);
                instance.cancelCameraFollowTween();
                instance.cameraFollowPoint.setPosition(targetX, targetY);
            case 'INSTANT':
                instance.tweenCameraToPosition(targetX, targetY, 0);
            default:
                var durSeconds = Conductor.instance.stepLengthMs * duration / 1000;
                var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, ease);
                if (easeFunction == null)
                {
                  trace('Invalid ease function: $ease');
                  return;
                }
                PlayState.instance.tweenCameraToPosition(targetX, targetY, durSeconds, easeFunction);
        }
    }

    public override function getTitle():String  return 'Focus Camera';

    public override function getEventSchema():SongEventSchema
    {
        return new SongEventSchema([
            {
                name: "char",
                title: "Target",
                defaultValue: 0,
                type: SongEventFieldType.ENUM,
                keys: ["Position" => -1, "Player" => 0, "Opponent" => 1, "Girlfriend" => 2]
            },
            {
                name: "x",
                title: "X Position",
                defaultValue: 0,
                step: 10.0,
                type: SongEventFieldType.FLOAT,
                units: "px"
            },
            {
                name: "y",
                title: "Y Position",
                defaultValue: 0,
                step: 10.0,
                type: SongEventFieldType.FLOAT,
                units: "px"
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
                  'Elastic In/Out' => 'elasticInOut',
                  'Instant (Ignores duration)' => 'INSTANT',
                  'Classic (Ignores duration)' => 'CLASSIC'
                ]
            }
        ]);
    }
}