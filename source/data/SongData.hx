package data;

@:nullSafety
typedef SongData = {
    @:default(data.registry.SongRegistry.SONG_DATA_VERSION)
    var version:String;

    var name:String;

    var notes:Array<SwagSection>;
    @:default([])
    @:optional
    var events:Array<Dynamic>;

	var bpm:Float;
    @:default(true)
    @:optional
	var needsVoices:Bool;
    @:default(1)
    @:optional
	var speed:Float;

    @:default(['bf', 'dad', 'gf'])
    @:optional
	var characters:Array<String>;
    @:default('stage')
    @:optional
	var stage:String;
    @:default('base')
    @:optional
	var assetModifier:String;
    @:default('')
    @:optional
	var arrowSkin:String;
    @:default('')
    @:optional
	var splashSkin:String;
    @:default(true)
    @:optional
	var validScore:Bool;
    @:default('')
    @:optional
	var variation:String;
}

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
    @:default(4)
    @:optional
	var sectionBeats:Float;
    @:default(false)
    @:optional
	var mustHitSection:Bool;
    @:default(150)
    @:optional
	var bpm:Float;
    @:default(false)
    @:optional
	var changeBPM:Bool;
}

typedef SwagEvent = 
{
	var strumTime:Float;
	var name:String;
	var values:Array<String>;
}