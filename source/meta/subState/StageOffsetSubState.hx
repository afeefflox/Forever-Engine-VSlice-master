package meta.subState;
import meta.subState.stage.StageEditorCommand;
@:allow(meta.subState.stage.StageEditorCommand)
class StageOffsetSubState extends HaxeUISubState
{
    private var char:FlxSprite = null;
    var outlineShader:StrokeShader;
    public function new()
    {
        super(Paths.xml('ui/stage-editor/stage-editor-view'));
    }

    override function create()
    {
        super.create();
        FlxG.mouse.visible = true;
        PlayState.instance.disableKeys = true;
        PlayState.pauseMusic();
        PlayState.instance.cancelAllCameraTweens();
        FlxG.camera.target = null;
        setupUIListeners();
        component.cameras = [PlayState.instance.camAlt];
        outlineShader = new StrokeShader(0xFFFFFFFF, 4, 4);
        var layerList:ListView = findComponent("prop-layers");

        for (thing in PlayState.instance.stage)
            {
              var prop:StageProp = cast thing;
              if (prop != null && prop.name != null)
              {
                layerList.dataSource.add(
                  {
                    item: prop.name,
                    complete: true,
                    id: 'swag'
                  });
              }
        
              FlxMouseEvent.add(thing, spr -> {
                // onMouseClick
        
                trace(spr);
        
                var dyn:StageProp = cast spr;
                if (dyn != null && dyn.name != null)
                {
                  if (FlxG.keys.pressed.CONTROL && char != dyn) selectProp(dyn.name);
                }
              });
            }
    }

    function selectProp(id:String)
    {
        if (char != null && char.color != FlxColor.WHITE) char.color = FlxColor.WHITE;

        var proptemp:FlxSprite = null;
        if(PlayState.instance.stage.existsCharacter(id))
            proptemp = cast PlayState.instance.stage.getCharacter(id);
        else if(PlayState.instance.stage.existsNamedProp(id)) 
            proptemp = cast PlayState.instance.stage.getNamedProp(id);
    
        if (proptemp == null) return;

        performCommand(new SelectPropCommand(proptemp));
        
        setUIValue('propXPos', Std.int(char.x));
        setUIValue('propYPos', Std.int(char.y));

        setUIValue('propXScroll', char.scrollFactor.x);
        setUIValue('propYScroll', char.scrollFactor.y);

        setUIValue('zIndex', char.zIndex);
    }

    function setupUIListeners()
    {
        addUIClickListener('save', saveStage);
        
        addUIChangeListener('propXPos', (event:UIEvent) -> {if (char != null) char.x = Std.int(event.value);});
        addUIChangeListener('propYPos', (event:UIEvent) -> {if (char != null) char.y = Std.int(event.value);});

        addUIChangeListener('propXScroll', (event:UIEvent) -> {if (char != null) char.scrollFactor.x = event.value;});
        addUIChangeListener('propYScroll', (event:UIEvent) -> {if (char != null) char.scrollFactor.y = event.value;});

        addUIChangeListener('zIndex', (event:UIEvent) -> {
            if (char != null)
            {
                char.zIndex = event.value;
                PlayState.instance.stage.refresh();			
            }
        });

        setUICheckboxSelected("HUD", PlayState.instance.camHUD.visible);
    }

    var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
    var undoOffsets:Array<Float> = null;
    var copiedOffset:Array<Float> = [0, 0];
    var colorSine:Float = 0;

    var mosPosOld:FlxPoint = new FlxPoint();
    var sprOld:FlxPoint = new FlxPoint();
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if(FlxG.keys.pressed.SHIFT)
		{
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

        // CAMERA CONTROLS
		if (FlxG.keys.pressed.J) FlxG.camera.scroll.x -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K) FlxG.camera.scroll.y += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L) FlxG.camera.scroll.x += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I) FlxG.camera.scroll.y -= elapsed * 500 * shiftMult * ctrlMult;

		var lastZoom = FlxG.camera.zoom;
		if(FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL) FlxG.camera.zoom = 1;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
		}
		else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
		}
        colorSine += elapsed;
        if (char != null)
        {
            var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
            char.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999);
            if(FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
                performCommand(new MovePropCommand(FlxG.mouse.deltaScreenX, FlxG.mouse.deltaScreenY, false));
            setUIValue('propXPos', Std.int(char.x));
            setUIValue('propYPos', Std.int(char.y));
            var zoomShitLol:Float = 2 / FlxG.camera.zoom;

            if (FlxG.keys.justPressed.LEFT) performCommand(new MovePropCommand(-zoomShitLol * shiftMult * ctrlMult, 0));
            if (FlxG.keys.justPressed.RIGHT) performCommand(new MovePropCommand(zoomShitLol * shiftMult * ctrlMult, 0));
            if (FlxG.keys.justPressed.UP) performCommand(new MovePropCommand(0, -zoomShitLol * shiftMult * ctrlMult));
            if (FlxG.keys.justPressed.DOWN) performCommand(new MovePropCommand(0, zoomShitLol * shiftMult * ctrlMult));            
        }

        FlxG.mouse.visible = true;


        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z) undoLastCommand();

        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.ENTER)
        {
            for (thing in PlayState.instance.stage)
            {
                FlxMouseEvent.remove(thing);
                thing.alpha = 1;
            }
            PlayState.instance.disableKeys = false;
            PlayState.instance.resetCamera();
            FlxG.mouse.visible = false;
            close();
        }
    }

    var commandStack:Array<StageEditorCommand> = [];
    var curOperation:Int = -1; // -1 at default, arrays start at 0
  
    function performCommand(command:StageEditorCommand):Void
    {
        command.execute(this);
        commandStack.push(command);
        curOperation++;
        if (curOperation < commandStack.length - 1) commandStack = commandStack.slice(0, curOperation + 1);
    }

    function undoCommand(command:StageEditorCommand):Void
    {
        command.undo(this);
        curOperation--;        
    }

    function undoLastCommand():Void
    {
        if (curOperation == -1 || commandStack.length == 0) return;
        var command = commandStack[curOperation];
        undoCommand(command);        
    }

    var _file:FileReference;
	function onSaveComplete(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

    function onSaveCancel(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

    function onSaveError(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

    function saveStage(_) 
    {
        if(_file != null) return;

		var data:String = prepStageStuff();
        
        if ((data != null) && (data.length > 0)) 
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), '${PlayState.instance.stage.id}.json');
		}
    }

    function prepStageStuff():String
    {
        var stageData:StageData = StageRegistry.instance.fetchEntry(PlayState.instance.stage.id)?._data;

        if (stageData == null)
        {
            FlxG.log.error('Stage of ${PlayState.instance.stage.id} not found in registry!');
            return "";
        }

        for (prop in stageData.props)
        {
            @:privateAccess
            var posStuff = PlayState.instance.stage.namedProps.get(prop.name);
      
            prop.position[0] = Std.int(posStuff.x);
            prop.position[1] = Std.int(posStuff.y);
            prop.zIndex = Std.int(posStuff.zIndex);
            prop.scroll[0] = posStuff.scrollFactor.x;
            prop.scroll[1] = posStuff.scrollFactor.y;
        }

        if(PlayState.instance.stage.getBoyfriend() != null)
        {
            var bfPos = PlayState.instance.stage.getBoyfriend().feetPosition;
            stageData.characters.bf.position[0] = Std.int(bfPos.x);
            stageData.characters.bf.position[1] = Std.int(bfPos.y);
            stageData.characters.bf.zIndex = Std.int(PlayState.instance.stage.getBoyfriend().zIndex);
            stageData.characters.bf.scroll[0] = PlayState.instance.stage.getBoyfriend().scrollFactor.x;
            stageData.characters.bf.scroll[1] = PlayState.instance.stage.getBoyfriend().scrollFactor.y;
        }

        if(PlayState.instance.stage.getDad() != null)
        {
            var dadPos = PlayState.instance.stage.getDad().feetPosition;
            stageData.characters.dad.position[0] = Std.int(dadPos.x);
            stageData.characters.dad.position[1] = Std.int(dadPos.y);
            stageData.characters.dad.zIndex = Std.int(PlayState.instance.stage.getDad().zIndex);
            stageData.characters.dad.scroll[0] = PlayState.instance.stage.getDad().scrollFactor.x;
            stageData.characters.dad.scroll[1] = PlayState.instance.stage.getDad().scrollFactor.y;
        }
        
        if(PlayState.instance.stage.getGirlfriend() != null)
        {
            var gfPos = PlayState.instance.stage.getGirlfriend().feetPosition;
            stageData.characters.gf.position[0] = Std.int(gfPos.x);
            stageData.characters.gf.position[1] = Std.int(gfPos.y);
            stageData.characters.gf.zIndex = Std.int(PlayState.instance.stage.getGirlfriend().zIndex);
            stageData.characters.gf.scroll[0] = PlayState.instance.stage.getGirlfriend().scrollFactor.x;
            stageData.characters.gf.scroll[1] = PlayState.instance.stage.getGirlfriend().scrollFactor.y;
        }

        stageData.updateVersionToLatest();
        var data:String = FunkyJson.stringify(stageData, "\t");
        return data;
    }
}