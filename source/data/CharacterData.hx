package data;


/**
 * Describes the available rendering types for a character.
 */
 enum abstract CharacterRenderType(String) from String to String
 {
   /**
    * Renders the character using a single spritesheet and XML data.
    */
   public var Atlas = 'atlas';

   /**
    * Renders the character using multiple spritesheets and XML data.
    */
   public var MultiAtlas = 'multiatlas';
 
   /**
    * Renders the character using a spritesheet of symbols and JSON data.
    */
   public var AnimateAtlas = 'animateatlas';
 
   /**
    * Renders the character using a custom method.
    */
   public var Custom = 'custom';
 }
 
 /**
  * The JSON data schema used to define a character.
  */
 typedef CharacterData =
 {
   /**
    * The sematic version number of the character data JSON format.
    */
   var version:String;
 
   /**
    * The readable name of the character.
    */
   var name:String;
 
   /**
    * The type of rendering system to use for the character.
    * @default sparrow
    */
   var renderType:CharacterRenderType;
 
   /**
    * Behavior varies by render type:
    * - SPARROW: Path to retrieve both the spritesheet and the XML data from.
    * - PACKER: Path to retrieve both the spritsheet and the TXT data from.
    */
   var assetPath:String;
 
   /**
    * The scale of the graphic as a float.
    * Pro tip: On pixel-art levels, save the sprites small and set this value to 6 or so to save memory.
    * @default 1
    */
   var scale:Null<Float>;
 
   /**
    * Optional data about the health icon for the character.
    */
   var healthIcon:Null<HealthIconData>;
 
   var death:Null<DeathData>;
 
   /**
    * The global offset to the character's position, in pixels.
    * @default [0, 0]
    */
   var offsets:Null<Array<Float>>;
 
   /**
    * The amount to offset the camera by while focusing on this character.
    * Default value focuses on the character directly.
    * @default [0, 0]
    */
   var cameraOffsets:Array<Float>;
 
   /**
    * Setting this to true disables anti-aliasing for the character.
    * @default false
    */
   var antialiasing:Null<Bool>;

   /**
    * An optional array of animations which the character can play.
    */
   var animations:Array<AnimationData>;
 
   /**
    * Whether or not the whole ass sprite is flipped by default.
    * Useful for characters that could also be played (Pico)
    *
    * @default false
    */
   var flipX:Null<Bool>;
 
   /**
    * Setting this to true flipped Offset and animation for the character that playable like bf.
    * @default false
    */
   var isPlayer:Null<Bool>;

   var iconPixelChar:String;
 };
 
 /**
  * The JSON data schema used to define the health icon for a character.
  */
 typedef HealthIconData =
 {
   /**
    * The ID to use for the health icon.
    * @default The character's ID
    */
   var id:Null<String>;
 
   /**
    * The scale of the health icon.
    */
   var scale:Null<Float>;
 
   /**
    * Whether to flip the health icon horizontally.
    * @default false
    */
   var flipX:Null<Bool>;
 
   /**
    * well no one care if icon was 32 bit rather than focus week 6 icons lol
    * @default false
    */
   var antialiasing:Null<Bool>;
 
   /**
    * The offset of the health icon, in pixels.
    * @default [0, 25]
    */
   var offsets:Null<Array<Float>>;
 }
 
 typedef DeathData =
 {
   /**
    * The amount to offset the camera by while focusing on this character as they die.
    * Default value focuses on the character's graphic midpoint.
    * @default [0, 0]
    */
   var ?cameraOffsets:Array<Float>;
 
   /**
    * The amount to zoom the camera by while focusing on this character as they die.
    * Value is a multiplier of the default camera zoom for the stage.
    * @default 1.0
    */
   var ?cameraZoom:Float;
 
   /**
    * Impose a delay between when the character reaches `0` health and when the death animation plays.
    * @default 0.0
    */
   var ?preTransitionDelay:Float;
 }
 