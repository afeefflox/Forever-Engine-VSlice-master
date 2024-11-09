package data;

typedef AlbumData =
{
  /**
   * Semantic version for album data.
   */
  public var version:String;

  /**
   * Readable name of the album.
   */
  public var name:String;

  /**
   * Readable name of the artist(s) of the album.
   */
  public var artists:Array<String>;

  /**
   * Asset key for the album art.
   * The album art will be displayed in Freeplay.
   */
  public var albumArtAsset:String;

  /**
   * Asset key for the album title.
   * The album title will be displayed below the album art in Freeplay.
   */
  public var albumTitleAsset:String;

  /**
   * An optional array of animations for the album title.
   */
  @:optional
  @:default([])
  public var albumTitleAnimations:Array<AnimationData>;
}