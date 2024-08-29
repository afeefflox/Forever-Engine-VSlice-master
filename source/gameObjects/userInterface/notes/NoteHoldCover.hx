package gameObjects.userInterface.notes;

class NoteHoldCover extends FNFSprite
{

    public var strumTime:Float = 0;
    public var id:Int = 0;
    public function new(id:Int = 0) 
    {
        super();
        this.id = id;
        ID = id;

        frames = Paths.getSparrowAtlas('noteskins/notes/default/base/holdCover');
        animation.addByPrefix('start', 'holdCoverStart${UIStaticArrow.getColorFromNumber(id)}', 24, false);
		animation.addByPrefix('loop', 'holdCover${UIStaticArrow.getColorFromNumber(id)}0', 24, true);
        offset.set(106, 99);

        animation.finishCallback = function(name:String) {
            if (name.startsWith('start'))
                playAnim('loop');
        };

        scrollFactor.set();
        visible = false;
        alpha = (Init.trueSettings.get('Opaque Arrows')) ? 1 : 0.6;
    }

    override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		// make sure the animation is visible
		if (!Init.trueSettings.get('Disable Note Splashes'))
			visible = true;

		super.playAnim(AnimName, Force, Reversed, Frame);
	}
}