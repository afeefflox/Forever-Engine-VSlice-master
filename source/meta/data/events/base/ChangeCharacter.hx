package meta.data.events.base;

using data.registry.CharacterRegistry;

class ChangeCharacter extends SongEvent
{
    public function new() 
    {
        super('ChangeCharacter');
    }



    var boyfriendMap:Map<String, BaseCharacter> = new Map<String, BaseCharacter>();
	var dadMap:Map<String, BaseCharacter> = new Map<String, BaseCharacter>();
	var gfMap:Map<String, BaseCharacter> = new Map<String, BaseCharacter>();

    public override function precacheEvent(data:SongEventData)
    {
        if (PlayState.isNull()) return;

        var type:Null<Int> = data.getInt('char');
        if (type == null) type = cast data.value;

        var charId:Null<String> = data.getString('charId').toLowerCase();
        if (charId == null) charId = 'bf';

        var newChar:BaseCharacter = BaseCharacter.fetchData(charId);

        switch(type) 
        {
            case 0:
                if(!boyfriendMap.exists(charId)) {
                    newChar.characterType = CharacterType.BF;
					boyfriendMap.set(charId, newChar);
                    trace('Precache Player: ${charId}');
				}
                
            case 1:
                if(!dadMap.exists(charId)) {
                    newChar.characterType = CharacterType.DAD;
					dadMap.set(charId, newChar);
                    trace('Precache Opponent: ${charId}');
				}
            case 2:
                if(!gfMap.exists(charId)) {
                    newChar.characterType = CharacterType.GF;
					gfMap.set(charId, newChar);
                    trace('Precache Girlfriend: ${charId}');
				}
        }
    }

    public override function handleEvent(data:SongEventData)
    {
        if (PlayState.isNull()) return;

        var char:Null<Int> = data.getInt('char');
        if (char == null) char = cast data.value;

        var charId:Null<String> = data.getString('charId').toLowerCase();
        if (charId == null) charId = 'bf';

        var stage = PlayState.instance.stage;
        var uiHUD = PlayState.instance.uiHUD;

        switch(char)
        {
            case 0:
                var newChar:BaseCharacter = boyfriendMap.get(charId);
                if(charCheck(stage.getBoyfriend(), newChar)) return;
                stage.getBoyfriend().destroy();
                if (newChar != null) {
                    stage.addCharacter(newChar, newChar.characterType);
                    uiHUD.iconP1.initHealthIcon(newChar._data.healthIcon);
                }
            case 1:
                var newChar:BaseCharacter = dadMap.get(charId);
                if(charCheck(stage.getDad(), newChar)) return;
                stage.getDad().destroy();
                if (newChar != null) {
                    stage.addCharacter(newChar, newChar.characterType);
                    uiHUD.iconP2.initHealthIcon(newChar._data.healthIcon);
                }
            case 2:
                var newChar:BaseCharacter = gfMap.get(charId);
                if(charCheck(stage.getGirlfriend(), newChar)) return;
                stage.getGirlfriend().destroy();
                if (newChar != null)  stage.addCharacter(newChar, newChar.characterType);
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
                name: "charId",
                title: "Character Name",
                defaultValue: "bf",
                type: SongEventFieldType.CHARACTER,
            }
        ]);
    }
}