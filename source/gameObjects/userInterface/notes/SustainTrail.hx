package gameObjects.userInterface.notes;

import gameObjects.userInterface.notes.notestyle.NoteStyle;
import flixel.util.FlxDirectionFlags;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMath;

class SustainTrail extends FlxSprite
{
    static final TRIANGLE_VERTEX_INDICES:Array<Int> = [0, 1, 2, 1, 2, 3, 4, 5, 6, 5, 6, 7];

    public var strumTime:Float = 0; // millis
    public var noteDirection:NoteDirection = 0;
    public var sustainLength(default, set):Float = 0; // millis
    public var fullSustainLength:Float = 0;
    public var noteData:Null<NoteJson>;
    public var parentStrumline:Strumline;
  
    public var cover:NoteHoldCover = null;

    public var hitNote:Bool = false;
    public var missedNote:Bool = false;
    public var handledMiss:Bool = false;
    public var vertices:DrawData<Float> = new DrawData<Float>();
    public var indices:DrawData<Int> = new DrawData<Int>();
    public var uvtData:DrawData<Float> = new DrawData<Float>();

    private var processedGraphic:FlxGraphic;
    private var zoom:Float = 1;

    public var endOffset:Float = 0.5; // 0.73 is roughly the bottom of the sprite in the normal graphic!
    public var bottomClip:Float = 0.9;
  
    public var isPixel:Bool;
  
    var graphicWidth:Float = 0;
    var graphicHeight:Float = 0;

    public function new(noteDirection:NoteDirection, sustainLength:Float, noteStyle:NoteStyle)
    {
        super(0, 0);

        // BASIC SETUP
        this.sustainLength = sustainLength;
        this.fullSustainLength = sustainLength;
        this.noteDirection = noteDirection;
    
        setupHoldNoteGraphic(noteStyle);
    
        indices = new DrawData<Int>(12, true, TRIANGLE_VERTEX_INDICES);
    
        this.active = true; // This NEEDS to be true for the note to be drawn!
    }

    public function setupHoldNoteGraphic(noteStyle:NoteStyle):Void
    {
        loadGraphic(noteStyle.getHoldNoteAssetPath());

        antialiasing = true;
    
        this.isPixel = noteStyle.isHoldNotePixel();
        if (isPixel)
        {
          endOffset = bottomClip = 1;
          antialiasing = false;
        }
        else
        {
          endOffset = 0.5;
          bottomClip = 0.9;
        }
    
        zoom = 1.0;
        zoom *= noteStyle.fetchHoldNoteScale();
        zoom *= 0.7;
    
        // CALCULATE SIZE
        graphicWidth = graphic.width / 8 * zoom; // amount of notes * 2
        graphicHeight = sustainHeight(sustainLength, parentStrumline?.scrollSpeed ?? 1.0);
        // instead of scrollSpeed, PlayState.SONG.speed
    
        flipY = Init.trueSettings.get('Downscroll');
    
        alpha = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;
        updateColorTransform();
    
        updateClipping();        
    }

    function getBaseScrollSpeed()
    {
        return (PlayState.SONG?.speed ?? 1.0);
    }

    var previousScrollSpeed:Float = 1;

    override function update(elapsed)
    {
        super.update(elapsed);
        if (previousScrollSpeed != (parentStrumline?.scrollSpeed ?? 1.0))
        {
          triggerRedraw();
        }
        previousScrollSpeed = parentStrumline?.scrollSpeed ?? 1.0;
    }

    public static inline function sustainHeight(susLength:Float, scroll:Float)
    {
        return (susLength * Constants.PIXELS_PER_MS * scroll);
    }
    function set_sustainLength(s:Float):Float
    {
        if (s < 0.0) s = 0.0;
      
        if (sustainLength == s) return s;
        this.sustainLength = s;
        triggerRedraw();
        return this.sustainLength;
    }

    function triggerRedraw()
    {
        graphicHeight = sustainHeight(sustainLength, parentStrumline?.scrollSpeed ?? 1.0);
        updateClipping();
        updateHitbox();
    }

    public override function updateHitbox():Void
    {
        this.width = this.graphicWidth;
        this.height = this.graphicHeight;
        this.offset.set(0, 0);
        this.origin.set(this.width * 0.5, this.height * 0.5);
    }

    public function updateClipping(songTime:Float = 0):Void
    {
        if (graphic == null) return;
        var clipHeight:Float = FlxMath.bound(sustainHeight(sustainLength - (songTime - strumTime), parentStrumline?.scrollSpeed ?? 1.0), 0, graphicHeight);
        if (clipHeight <= 0.1)
        {
            visible = false;
            return;
        }
        else
        {
            visible = true;
        }
        
            var bottomHeight:Float = graphic.height * zoom * endOffset;
            var partHeight:Float = clipHeight - bottomHeight;
        
            // ===HOLD VERTICES==
            // Top left
            vertices[0 * 2] = 0.0; // Inline with left side
            vertices[0 * 2 + 1] = flipY ? clipHeight : graphicHeight - clipHeight;
        
            // Top right
            vertices[1 * 2] = graphicWidth;
            vertices[1 * 2 + 1] = vertices[0 * 2 + 1]; // Inline with top left vertex
        
            // Bottom left
            vertices[2 * 2] = 0.0; // Inline with left side
            vertices[2 * 2 + 1] = if (partHeight > 0)
            {
              // flipY makes the sustain render upside down.
              flipY ? 0.0 + bottomHeight : vertices[1] + partHeight;
            }
            else
            {
              vertices[0 * 2 + 1]; // Inline with top left vertex (no partHeight available)
            }
        
            // Bottom right
            vertices[3 * 2] = graphicWidth;
            vertices[3 * 2 + 1] = vertices[2 * 2 + 1]; // Inline with bottom left vertex
        
            // ===HOLD UVs===
        
            // The UVs are a bit more complicated.
            // UV coordinates are normalized, so they range from 0 to 1.
            // We are expecting an image containing 8 horizontal segments, each representing a different colored hold note followed by its end cap.
        
            uvtData[0 * 2] = 1 / 4 * (noteDirection % 4); // 0%/25%/50%/75% of the way through the image
            uvtData[0 * 2 + 1] = (-partHeight) / graphic.height / zoom; // top bound
            // Top left
        
            // Top right
            uvtData[1 * 2] = uvtData[0 * 2] + 1 / 8; // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left)
            uvtData[1 * 2 + 1] = uvtData[0 * 2 + 1]; // top bound
        
            // Bottom left
            uvtData[2 * 2] = uvtData[0 * 2]; // 0%/25%/50%/75% of the way through the image
            uvtData[2 * 2 + 1] = 0.0; // bottom bound
        
            // Bottom right
            uvtData[3 * 2] = uvtData[1 * 2]; // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left)
            uvtData[3 * 2 + 1] = uvtData[2 * 2 + 1]; // bottom bound
        
            // === END CAP VERTICES ===
            // Top left
            vertices[4 * 2] = vertices[2 * 2]; // Inline with bottom left vertex of hold
            vertices[4 * 2 + 1] = vertices[2 * 2 + 1]; // Inline with bottom left vertex of hold
        
            // Top right
            vertices[5 * 2] = vertices[3 * 2]; // Inline with bottom right vertex of hold
            vertices[5 * 2 + 1] = vertices[3 * 2 + 1]; // Inline with bottom right vertex of hold
        
            // Bottom left
            vertices[6 * 2] = vertices[2 * 2]; // Inline with left side
            vertices[6 * 2 + 1] = flipY ? (graphic.height * (-bottomClip + endOffset) * zoom) : (graphicHeight + graphic.height * (bottomClip - endOffset) * zoom);
        
            // Bottom right
            vertices[7 * 2] = vertices[3 * 2]; // Inline with right side
            vertices[7 * 2 + 1] = vertices[6 * 2 + 1]; // Inline with bottom of end cap
        
            // === END CAP UVs ===
            // Top left
            uvtData[4 * 2] = uvtData[2 * 2] + 1 / 8; // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left of hold)
            uvtData[4 * 2 + 1] = if (partHeight > 0)
            {
              0;
            }
            else
            {
              (bottomHeight - clipHeight) / zoom / graphic.height;
            };
        
            // Top right
            uvtData[5 * 2] = uvtData[4 * 2] + 1 / 8; // 25%/50%/75%/100% of the way through the image (1/8th past the top left of cap)
            uvtData[5 * 2 + 1] = uvtData[4 * 2 + 1]; // top bound
        
            // Bottom left
            uvtData[6 * 2] = uvtData[4 * 2]; // 12.5%/37.5%/62.5%/87.5% of the way through the image (1/8th past the top left of hold)
            uvtData[6 * 2 + 1] = bottomClip; // bottom bound
        
            // Bottom right
            uvtData[7 * 2] = uvtData[5 * 2]; // 25%/50%/75%/100% of the way through the image (1/8th past the top left of cap)
            uvtData[7 * 2 + 1] = uvtData[6 * 2 + 1]; // bottom bound        
    }

    @:access(flixel.FlxCamera)
    override public function draw():Void
    {
      if (alpha == 0 || graphic == null || vertices == null) return;
  
      for (camera in cameras)
      {
        if (!camera.visible || !camera.exists) continue;
        // if (!isOnScreen(camera)) continue; // TODO: Update this code to make it work properly.
  
        getScreenPosition(_point, camera).subtractPoint(offset);
        camera.drawTriangles(processedGraphic, vertices, indices, uvtData, null, _point, blend, true, antialiasing);
      }
  
      #if FLX_DEBUG
      if (FlxG.debugger.drawDebug) drawDebug();
      #end
    }


    public override function kill():Void
      {
        super.kill();
    
        strumTime = 0;
        noteDirection = 0;
        sustainLength = 0;
        fullSustainLength = 0;
        noteData = null;
    
        hitNote = false;
        missedNote = false;
      }
    
      public override function revive():Void
      {
        super.revive();
    
        strumTime = 0;
        noteDirection = 0;
        sustainLength = 0;
        fullSustainLength = 0;
        noteData = null;
    
        hitNote = false;
        missedNote = false;
        handledMiss = false;
      }
    
      override public function destroy():Void
      {
        vertices = null;
        indices = null;
        uvtData = null;
        processedGraphic.destroy();
    
        super.destroy();
      }
    
      override function updateColorTransform():Void
      {
        super.updateColorTransform();
        if (processedGraphic != null) processedGraphic.destroy();
        processedGraphic = FlxGraphic.fromGraphic(graphic, true);
        processedGraphic.bitmap.colorTransform(processedGraphic.bitmap.rect, colorTransform);
      }
}