package data;
@:nullSafety
class StageData
{
  /**
   * The sematic version number of the stage data JSON format.
   * Supports fancy comparisons like NPM does it's neat.
   */
  @:default(data.registry.StageRegistry.STAGE_DATA_VERSION)
  public var version:String;

  public var name:String = 'Unknown';
  public var props:Array<StageDataProp> = [];
  public var characters:StageDataCharacters;

  @:default(1.0)
  @:optional
  public var cameraZoom:Null<Float>;

  @:default("")
  @:optional
  public var library:Null<String>;

  @:default("")
  @:optional
  public var folder:Null<String>;

  public function new()
  {
    this.version = StageRegistry.STAGE_DATA_VERSION;
    this.characters = makeDefaultCharacters();
  }

  function makeDefaultCharacters():StageDataCharacters
  {
    return {
      bf:
        {
          zIndex: 0,
          scale: 1,
          position: [0, 0],
          cameraOffsets: [-100, -100]
        },
      dad:
        {
          zIndex: 0,
          scale: 1,
          position: [0, 0],
          cameraOffsets: [100, -100]
        },
      gf:
        {
          zIndex: 0,
          scale: 1,
          position: [0, 0],
          cameraOffsets: [0, 0]
        }
    };
  }

  public function updateVersionToLatest():Void
  {
    this.version = StageRegistry.STAGE_DATA_VERSION;
  }
}

typedef StageDataCharacters =
{
  var bf:StageDataCharacter;
  var dad:StageDataCharacter;
  var gf:StageDataCharacter;
};

typedef StageDataProp =
{
  /**
   * The name of the prop for later lookup by scripts.
   * Optional; if unspecified, the prop can't be referenced by scripts.
   */
  @:optional
  var name:String;

  /**
   * The asset used to display the prop.
   * NOTE: As of Stage data v1.0.1, you can also use a color here to create a rectangle, like "#ff0000".
   * In this case, the `scale` property will be used to determine the size of the prop.
   */
  var assetPath:String;

  /**
   * The position of the prop as an [x, y] array of two floats.
   */
  var position:Array<Float>;

  /**
   * A number determining the stack order of the prop, relative to other props and the characters in the stage.
   * Props with lower numbers render below those with higher numbers.
   * This is just like CSS, it isn't hard.
   * @default 0
   */
  @:optional
  @:default(0)
  var zIndex:Int;

  /**
   * If set to true, anti-aliasing will be forcibly disabled on the sprite.
   * This prevents blurry images on pixel-art levels.
   * @default true
   */
  @:optional
  @:default(true)
  var antialiasing:Bool;

  /**
   * Either the scale of the prop as a float, or the [w, h] scale as an array of two floats.
   * Pro tip: On pixel-art levels, save the sprite small and set this value to 6 or so to save memory.
   */
  @:jcustomparse(data.DataParse.eitherFloatOrFloats)
  @:jcustomwrite(data.DataWrite.eitherFloatOrFloats)
  @:optional
  @:default(Left(1.0))
  var scale:haxe.ds.Either<Float, Array<Float>>;

  /**
   * The alpha of the prop, as a float.
   * @default 1.0
   */
  @:optional
  @:default(1.0)
  var alpha:Float;

  /**
   * If not zero, this prop will play an animation every X beats of the song.
   * This requires animations to be defined. If `danceLeft` and `danceRight` are defined,
   * they will alternated between, otherwise the `idle` animation will be used.
   *
   * @default 0
   */
  
  @:optional
  @:default(0)
  var danceEvery:Int;

  /**
   * How much the prop scrolls relative to the camera. Used to create a parallax effect.
   * Represented as an [x, y] array of two floats.
   * [1, 1] means the prop moves 1:1 with the camera.
   * [0.5, 0.5] means the prop half as much as the camera.
   * [0, 0] means the prop is not moved.
   * @default [0, 0]
   */
  @:optional
  @:default([0, 0])
  var scroll:Array<Float>;

  /**
   * An optional array of animations which the prop can play.
   * @default Prop has no animations.
   */
  @:optional
  @:default([])
  var animations:Array<AnimationData>;

  @:optional
  var startingAnimation:Null<String>;

  /**
   * An optional Flip Horizontal the Sprites 
   * @default
   */
  @:optional
  @:default(false)
  var flipX:Bool;

  /**
   * An optional Flip vertical the Sprites 
   * @default
   */
  @:optional
  @:default(false)
  var flipY:Bool;
};

typedef StageDataCharacter =
{
  /**
   * A number determining the stack order of the character, relative to props and other characters in the stage.
   * Again, just like CSS.
   * @default 0
   */
  @:optional
  @:default(0)
  var zIndex:Int;

  /**
   * The position to render the character at.
   */
  @:optional
  @:default([0, 0])
  var position:Array<Float>;

  /**
   * The scale to render the character at.
   */
  @:optional
  @:default(1)
  var scale:Float;

    /**
   * How much the character scrolls relative to the camera. Used to create a parallax effect.
   * Represented as an [x, y] array of two floats.
   * [1, 1] means the character moves 1:1 with the camera.
   * [0.5, 0.5] means the character half as much as the camera.
   * [0, 0] means the character is not moved.
   * @default [1, 1]
   */
  @:optional
  @:default([1, 1])
  var scroll:Array<Float>;

  /**
   * The camera offsets to apply when focusing on the character on this stage.
   * @default [-100, -100] for BF, [100, -100] for DAD/OPPONENT, [0, 0] for GF
   */
  @:optional
  var cameraOffsets:Array<Float>;
};
