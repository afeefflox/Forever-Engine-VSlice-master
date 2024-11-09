package gameObjects.userInterface;

class PixelatedIcon extends FlxFilteredSprite
{
    public var char(default, set):Null<String>;
    public function new(char:String)
    {
        super(x, y);
        this.makeGraphic(32, 32, 0x00000000);
        this.antialiasing = false;
        this.active = false;
        this.char = char;
    }

    function set_char(value:Null<String>):Null<String>
    {
        if (value == char) return value;
		char = value ?? 'bf';
		setCharacter(char);
		return char;
    }

    public function setCharacter(char:String):Void
    {
        var charPath:String = 'icons/freeplay/${CharacterRegistry.fetchCharacterData(char).iconPixelChar}pixel';
        if (!openfl.utils.Assets.exists(Paths.image(charPath)))
        {
            trace('[WARN] Character ${char} has no freeplay icon.');
            this.visible = false;
            return;
        }
        else
        {
            this.visible = true;
        }
      
        var isAnimated = openfl.utils.Assets.exists(Paths.file('images/$charPath.xml'));
      
        if (isAnimated)
        {
            this.frames = Paths.getSparrowAtlas(charPath);
        }
        else
        {
            this.loadGraphic(Paths.image(charPath));
        }
      
        this.scale.x = this.scale.y = 2;
      
        switch (char)
        {
            case 'parents-christmas':
                this.origin.x = 140;
            default:
                this.origin.x = 100;
        }
      
        if (isAnimated)
        {
            this.active = true;
            this.animation.addByPrefix('idle', 'idle0', 10, true);
            this.animation.addByPrefix('confirm', 'confirm0', 10, false);
            this.animation.addByPrefix('confirm-hold', 'confirm-hold0', 10, true);
      
            this.animation.finishCallback = function(name:String):Void {
                trace('Finish pixel animation: ${name}');
                if (name == 'confirm') this.animation.play('confirm-hold');
            };
      
            this.animation.play('idle');
        }
    }  
}