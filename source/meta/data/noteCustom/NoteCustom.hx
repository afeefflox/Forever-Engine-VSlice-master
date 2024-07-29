package meta.data.noteCustom;
import data.NoteTypeData;
import data.registry.NoteTypeRegistry;
import data.registry.base.IRegistryEntry;

class NoteCustom implements IRegistryEntry<NoteTypeData>
{
    public final id:String;

    public final _data:NoteTypeData;

    public function new(id:String):Void
    {
        this.id = id;
        _data = _fetchData(id);
    }

    public function initFunction(note:Note) 
    {
        if(_data != null)
        {
            note.texture = _data.texture;
            note.mustPress = _data.mustPress;
            note.canBeHit = _data.canBeHit;
            note.tooLate = _data.tooLate;
            note.wasGoodHit = _data.wasGoodHit;
            note.animSuffix = _data.animSuffix;
            note.gfNote = _data.gfNote;
            note.ignoreNote = _data.ignoreNote;
            note.hitByOpponent = _data.hitByOpponent;
            note.noAnimation = _data.noAnimation;
            note.noMissAnimation = _data.noMissAnimation;
            note.hitCausesMiss = _data.hitCausesMiss;
        }

    }

    public function hitFunction(note:Note) 
    {

    }

    public function toString():String
    {
        return 'Note(' + this.id + ')';
    }

    public function destroy()
    {

    }

    static function _fetchData(id:String):Null<NoteTypeData>
    {
        return NoteTypeRegistry.instance.parseEntryDataWithMigration(id, NoteTypeRegistry.instance.fetchEntryVersion(id));
    }
}