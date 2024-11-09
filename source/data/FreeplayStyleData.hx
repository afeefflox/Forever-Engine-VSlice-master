package data;

typedef FreeplayStyleData =
{
  /**
   * Semantic version for style data.
   */
  public var version:String;

  /**
   * Asset key for the background image.
   */
  public var bgAsset:String;

  /**
   * Asset key for the difficulty selector image.
   */
  public var selectorAsset:String;

  /**
   * Asset key for the numbers shown at the top right of the screen.
   */
  public var numbersAsset:String;

  /**
   * Asset key for the freeplay capsules.
   */
  public var capsuleAsset:String;

  /**
   * Color data for the capsule text outline.
   * the order of this array goes as follows: [DESELECTED, SELECTED]
   */
  public var capsuleTextColors:Array<String>;

  /**
   * Delay time after confirming a song selection, before entering PlayState.
   * Useful for letting longer animations play out.
   */
  public var startDelay:Float;
}