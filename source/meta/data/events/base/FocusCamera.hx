package meta.data.events.base;

class FocusCamera extends Events
{
    public function new()
    {
        super('Focus Camera');
        this.values = [
            "0, 0",
            [
                "boyfriend",
                "dad",
                "gf"
            ],
            [
                //Entire List FlxEase Wow
                'classic',
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
            1
        ];
    }

    override function returnDescription():String
    {
        return 'Move Camera but it disable section camera \nValue 1: X and Y \nValue 2: Character \nValue 3: Ease \nValue 4: Duration';
    }

    override function initFunction(params:Array<Dynamic>)
    {
        super.initFunction(params);

        if(PlayState.isNull()) return;

        var values:Array<String> = params[0].split(',');
        var posY:Null<Float> = Std.parseFloat(values[0]);
		var posX:Null<Float> = Std.parseFloat(values[1]);
		if(Math.isNaN(posY)) posY = 0;
		if(Math.isNaN(posX)) posX = 0;
        
        PlayState.instance.disableCamera = true;

        var char:BaseCharacter = null;
        switch(params[1].toLowerCase()) 
        {
            default:
                char = PlayState.instance.stage.getBoyfriend();
            case 'dad':
                char = PlayState.instance.stage.getDad();
            case 'gf':
                char = PlayState.instance.stage.getGirlfriend();
        }

        if(char == null) return;

        switch(params[2].toLowerCase()) 
        {
            case 'classic':
                PlayState.instance.resetCamera(false, true);
                PlayState.instance.cameraFollowPoint.x = char.cameraFocusPoint.x + posX;
                PlayState.instance.cameraFollowPoint.y = char.cameraFocusPoint.y + posY;
            case 'instant':
                PlayState.instance.tweenCameraToPosition(char.cameraFocusPoint.x + posX, char.cameraFocusPoint.y + posY, 0);
            default:
                var durSeconds = Conductor.stepCrochet * params[3] / 1000; // heh why not?
                var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, params[2]);
                if (easeFunction == null)
                {
                    trace('Invalid ease function: ${params[2]}');
                    return;
                }
                PlayState.instance.tweenCameraToPosition(posX, posY, durSeconds, easeFunction);
        }
    }
}