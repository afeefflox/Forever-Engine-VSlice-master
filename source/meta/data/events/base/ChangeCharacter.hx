package meta.data.events.base;


class ChangeCharacter extends Events
{
    public function new()
    {
        super('Change Character');
        this.values = [
            [
                "boyfriend",
                "dad",
                "gf"
            ],
           "bf"
        ];
    }

    override function returnDescription():String
    {
        return 'Change Change to Other \nValue 1: Character \nValue 2: new Character Name';
    }

    override function initFunction(params:Array<Dynamic>)
    {
        super.initFunction(params);
        if(PlayState.isNull()) return;

        var stage = PlayState.instance.stage;
        switch(params[0]) 
        {
            default:
                stage.getBoyfriend().destroy();
                var character = BaseCharacter.fetchData(params[1].toLowerCase());
                if (character != null) {
                    character.characterType = CharacterType.BF;
                    stage.addCharacter(character, CharacterType.BF);
                    PlayState.instance.uiHUD.iconP1.char = character._data.healthIcon.id;
                }
            case 'dad':
                stage.getDad().destroy();
                var character = BaseCharacter.fetchData(params[1].toLowerCase());
                if (character != null) {
                    character.characterType = CharacterType.DAD;
                    stage.addCharacter(character, CharacterType.DAD);
                    PlayState.instance.uiHUD.iconP2.char = character._data.healthIcon.id;
                }
            case 'gf':
                stage.getGirlfriend().destroy();
                var character = BaseCharacter.fetchData(params[1].toLowerCase());
                if (character != null) {
                    character.characterType = CharacterType.GF;
                    stage.addCharacter(character, CharacterType.GF);
                }
        }
        stage.refresh();
    }
}