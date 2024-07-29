package data;

typedef NoteTypeData = {

    @:default(data.registry.NoteTypeRegistry.NOTETYPE_DATA_VERSION)
    var version:String;

    
    @:default('')
    @:optional
    var texture:String;

    @:default(true)
    @:optional
    var mustPress:Bool;

    @:default(true)
    @:optional
    var canBeHit:Bool;

    @:default(false)
    @:optional
    var tooLate:Bool;

    @:default(false)
    @:optional
    var wasGoodHit:Bool;


    @:default('')
    @:optional
    var animSuffix:String;


    @:default(false)
    @:optional
    var gfNote:Bool;

    @:default(false)
    @:optional
    var ignoreNote:Bool;

    @:default(false)
    @:optional
    var hitByOpponent:Bool;

    @:default(false)
    @:optional
    var noAnimation:Bool;

    @:default(false)
    @:optional
    var noMissAnimation:Bool;

    @:default(false)
    @:optional
    var hitCausesMiss:Bool;
}