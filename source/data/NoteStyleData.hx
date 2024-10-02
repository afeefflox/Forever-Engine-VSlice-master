package data;

typedef NoteStyleData =
{
  /**
   * The version number of the note style data schema.
   * When making changes to the note style data format, this should be incremented,
   * and a migration function should be added to NoteStyleDataParser to handle old versions.
   */    
    @:default(data.registry.NoteStyleRegistry.NOTE_STYLE_DATA_VERSION)
    var version:String;
  /**
   * The readable title of the note style.
   */
   var name:String;

   /**
    * The author of the note style.
    */
   var author:String;
 
   /**
    * The note style to use as a fallback/parent.
    * @default null
    */
   @:optional
   var fallback:Null<String>;
 
   /**
    * Data for each of the assets in the note style.
    */
   var assets:NoteStyleAssetsData;


}

typedef NoteStyleAssetsData =
{
    /**
    * The sprites for the notes.
    * @default The sprites from the fallback note style.
    */
   @:optional
   var note:NoteStyleAssetData<NoteStyleData_Note>;
 
   /**
    * The sprites for the hold notes.
    * @default The sprites from the fallback note style.
    */
   @:optional
   var holdNote:NoteStyleAssetData<NoteStyleData_HoldNote>;
 
   /**
    * The sprites for the strumline.
    * @default The sprites from the fallback note style.
    */
   @:optional
   var noteStrumline:NoteStyleAssetData<NoteStyleData_NoteStrumline>;
 
   /**
    * The sprites for the note splashes.
    */
   @:optional
   var noteSplash:NoteStyleAssetData<NoteStyleData_NoteSplash>;
 
   /**
    * The sprites for the hold note covers.
    */
   @:optional
   var holdNoteCover:NoteStyleAssetData<NoteStyleData_HoldNoteCover>;
 
   /**
    * The THREE sound (and an optional pre-READY graphic).
    */
   @:optional
   var countdownThree:NoteStyleAssetData<NoteStyleData_Countdown>;
 
   /**
    * The TWO sound and READY graphic.
    */
   @:optional
   var countdownTwo:NoteStyleAssetData<NoteStyleData_Countdown>;
 
   /**
    * The ONE sound and SET graphic.
    */
   @:optional
   var countdownOne:NoteStyleAssetData<NoteStyleData_Countdown>;
 
   /**
    * The GO sound and GO! graphic.
    */
   @:optional
   var countdownGo:NoteStyleAssetData<NoteStyleData_Countdown>;
   //**yeah it built diffrent so**/
    /**
    * The judgement.
    */
    @:optional
    var judgement:NoteStyleAssetData<NoteStyleData_Judgement>;

   /**The ComboNumber**/
 
   @:optional
   var combo:NoteStyleAssetData<NoteStyleData_ComboNum>;
}

/**
 * Data shared by all note style assets.
 */
 typedef NoteStyleAssetData<T> =
 {
   /**
    * The image to use for the asset. May be a Sparrow sprite sheet.
    */
   var assetPath:String;
 
   /**
    * The scale to render the prop at.
    * @default 1.0
    */
   @:default(1.0)
   @:optional
   var scale:Float;
 
   /**
    * Offset the sprite's position by this amount.
    * @default [0, 0]
    */
   @:default([0, 0])
   @:optional
   var offsets:Null<Array<Float>>;
 
   /**
    * If true, the prop is a pixel sprite, and will be rendered without anti-aliasing.
    */
   @:default(false)
   @:optional
   var isPixel:Bool;
 
   /**
    * If true, animations will be played on the graphic.
    * @default `false` to save performance.
    */
   @:default(false)
   @:optional
   var animated:Bool;
 
   /**
    * The structure of this data depends on the asset.
    */
   @:optional
   var data:Null<T>;

    /**
    * if Note were color as Red, Green and Blue
   **/
   @:default(false)
   @:optional
   var enabledRGB:Bool;
 }
 
 typedef NoteStyleData_Note =
 {
   var left:UnnamedAnimationData;
   var down:UnnamedAnimationData;
   var up:UnnamedAnimationData;
   var right:UnnamedAnimationData;
 }
 
 typedef NoteStyleData_Countdown =
 {
   var audioPath:String;
 }
 
 typedef NoteStyleData_HoldNote = {}
 typedef NoteStyleData_Judgement = {
  @:default(500)
  @:optional
  var width:Int;
  @:default(163)
  @:optional
  var height:Int;
 }
 typedef NoteStyleData_ComboNum = {
  @:default(100)
  @:optional
  var width:Int;
  @:default(140)
  @:optional
  var height:Int;
 }
 
 /**
  * Data on animations for each direction of the strumline.
  */
 typedef NoteStyleData_NoteStrumline =
 {
   var leftStatic:UnnamedAnimationData;
   var leftPress:UnnamedAnimationData;
   var leftConfirm:UnnamedAnimationData;
   var leftConfirmHold:UnnamedAnimationData;
   var downStatic:UnnamedAnimationData;
   var downPress:UnnamedAnimationData;
   var downConfirm:UnnamedAnimationData;
   var downConfirmHold:UnnamedAnimationData;
   var upStatic:UnnamedAnimationData;
   var upPress:UnnamedAnimationData;
   var upConfirm:UnnamedAnimationData;
   var upConfirmHold:UnnamedAnimationData;
   var rightStatic:UnnamedAnimationData;
   var rightPress:UnnamedAnimationData;
   var rightConfirm:UnnamedAnimationData;
   var rightConfirmHold:UnnamedAnimationData;
 }
 
 typedef NoteStyleData_NoteSplash =
 {
   /**
    * If false, note splashes are entirely hidden on this note style.
    * @default Note splashes are enabled.
    */
   @:optional
   @:default(true)
   var enabled:Bool;
 };
 
 typedef NoteStyleData_HoldNoteCover =
 {
   /**
    * If false, hold note covers are entirely hidden on this note style.
    * @default Hold note covers are enabled.
    */
   @:optional
   @:default(true)
   var enabled:Bool;
 };