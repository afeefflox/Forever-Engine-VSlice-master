package meta.data.events.base;

class ChangeCharacter extends SongEvent
{
    public function new() 
    {
        super('ChangeCharacter');
    }


    var charMap:Map<String, BaseCharacter> = new Map<String, BaseCharacter>();

    public override function precacheEvent(data:SongEventData)
    {
        if (PlayState.isNull()) return;

        var charId:Null<String> = data.getString('id').toLowerCase();
        if (charId == null) charId = 'bf';

        if(!charMap.exists(charId)) 
        {
            var character = BaseCharacter.fetchData(charId);
            charMap.set(charId, character);
            trace('Preacahe Character Id: ${charId}');
        }
    }

    public override function handleEvent(data:SongEventData)
    {
        if (PlayState.isNull()) return;

        var char:Null<Int> = data.getInt('char');
        if (char == null) char = cast data.value;

        var charId:Null<String> = data.getString('id').toLowerCase();
        if (charId == null) charId = 'bf';

        var stage = PlayState.instance.stage;
        var character:BaseCharacter = charMap.get(charId);

        switch(char)
        {
            case 0:
                if(charCheck(stage.getBoyfriend(), character)) return;
                
                stage.getBoyfriend().destroy();
                if (character != null) {
                    character.characterType = CharacterType.BF;
                    stage.addCharacter(character, CharacterType.BF);
                    PlayState.instance.uiHUD.iconP1.char = character._data.healthIcon.id;
                }
            case 1:
                if(charCheck(stage.getDad(), character)) return;

                stage.getDad().destroy();
                if (character != null) {
                    character.characterType = CharacterType.DAD;
                    stage.addCharacter(character, CharacterType.DAD);
                    PlayState.instance.uiHUD.iconP2.char = character._data.healthIcon.id;
                }
            case 2:
                if(charCheck(stage.getGirlfriend(), character)) return;

                stage.getGirlfriend().destroy();
                if (character != null) {
                    character.characterType = CharacterType.GF;
                    stage.addCharacter(character, CharacterType.GF);
                }
        }
        stage.refresh(); 
    }

    function charCheck(currentChar:BaseCharacter, newCharacter:BaseCharacter) {
        if (currentChar == null || newCharacter == null) return true;
        if (currentChar.id == newCharacter.id) return true;
        return false;
    }

    public override function getTitle():String  return 'Change Character';

    public override function getEventSchema():SongEventSchema
    {
        return new SongEventSchema([
            {
                name: "char",
                title: "Target",
                defaultValue: 0,
                type: SongEventFieldType.ENUM,
                keys: ["Player" => 0, "Opponent" => 1, "Girlfriend" => 2]
            },
            {
                name: "id",
                title: "Character Name",
                defaultValue: "bf",
                type: SongEventFieldType.CHARACTER,
            }
        ]);
    }
}