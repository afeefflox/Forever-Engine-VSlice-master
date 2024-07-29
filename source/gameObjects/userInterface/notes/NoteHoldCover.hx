package gameObjects.userInterface.notes;

class NoteHoldCover extends FNFSprite
{
    public function new() 
    {
        super();
		visible = false;
		
        scrollFactor.set();
    }

    var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
    public function setupNoteHoldCover(x:Float, y:Float, direction:Int = 0, ?note:Note = null) 
    {
        setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);

        frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset('holdCover', 'base', 'default', 'noteskins/notes'));
        for (i in 0...colArray.length)
        {
            animation.addByPrefix('start${colArray[i]}', 'holdCoverStart${colArray[i]}', 24, false);
            animation.addByPrefix('hold${colArray[i]}', 'holdCover${colArray[i]}', 24, true);
            animation.addByPrefix('end${colArray[i]}', 'holdCoverEnd${colArray[i]}', 24, false);
        }
        playAnim('start${UIStaticArrow.getColorFromNumber(direction)}', true);
        animation.finishCallback = function(name:String)
        {
            if (name.startsWith('start'))
                playAnim('hold${UIStaticArrow.getColorFromNumber(direction)}', true);
            if (name.startsWith('end')) //kill it would be end of world lmao
                if (visible) visible = false;
        };

        if(note != null && note.parentNote.childrenNotes.length <= 0)
            playAnim('end${UIStaticArrow.getColorFromNumber(direction)}', true);

        if (animation.getAnimationList().length < 3 * 4)
            trace('WARNING: NoteHoldCover failed to initialize all animations.');

        alpha = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;
    }

    override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		// make sure the animation is visible
		if (!Init.trueSettings.get('Disable Note Splashes'))
			visible = true;

		super.playAnim(AnimName, Force, Reversed, Frame);
	}
}