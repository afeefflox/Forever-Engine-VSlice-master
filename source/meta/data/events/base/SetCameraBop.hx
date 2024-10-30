package meta.data.events.base;

class SetCameraBop extends SongEvent
{
    public function new()
    {
        super('SetCameraBop');
    }

    public override function handleEvent(data:SongEventData)
    {
        if (PlayState.instance == null) return;

        var rate:Null<Int> = data.getInt('rate');
        if (rate == null) rate = Constants.DEFAULT_ZOOM_RATE;
        var intensity:Null<Float> = data.getFloat('intensity');
        if (intensity == null) intensity = 1.0;
    
        PlayState.instance.cameraBopIntensity = (Constants.DEFAULT_BOP_INTENSITY - 1.0) * intensity + 1.0;
        PlayState.instance.hudCameraZoomIntensity = (Constants.DEFAULT_BOP_INTENSITY - 1.0) * intensity * 2.0;
        PlayState.instance.cameraZoomRate = rate;
    }

    public override function getTitle():String return 'Set Camera Bop';

    public override function getEventSchema():SongEventSchema
    {
        return new SongEventSchema([
            {
              name: 'intensity',
              title: 'Intensity',
              defaultValue: 1.0,
              step: 0.1,
              type: SongEventFieldType.FLOAT,
              units: 'x'
            },
            {
              name: 'rate',
              title: 'Rate',
              defaultValue: 4,
              step: 1,
              type: SongEventFieldType.INTEGER,
              units: 'beats/zoom'
            }
        ]);
    }
}