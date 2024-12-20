package gameObjects.userInterface;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;

using StringTools;

class HealthIcon extends FunkinSprite
{
	// rewrite using da new icon system as ninjamuffin would say it
	public var char(default, set):Null<String>;
	public var isPlayer:Bool = false;

	public var sprTracker:FlxSprite;

	static final WINNING_THRESHOLD:Float = 80;
	static final LOSING_THRESHOLD:Float = 20;
	static final MAXIMUM_HEALTH:Float = 2;

	public function new(char:String = 'bf', ?isPlayer:Bool = false)
	{
		super();
		this.char = char;
		this.scrollFactor.set();
		this.flipX = this.isPlayer = isPlayer;
	}

	function set_char(value:Null<String>):Null<String>
	{
		if (value == char) return value;
		char = value ?? Constants.DEFAULT_HEALTH_ICON;
		updateIcon(char);
		return char;
	}

	public function updateIcon(id:String = 'bf')
	{
		if (id == null || correctCharacterId(id) != id)
		{
			char = correctCharacterId(id);
			return;
		}

		if (Paths.getExistAtlas('icons/icon-$id'))	
		{
			frames = Paths.getAtlas('icons/icon-$id');
			loadAnimationNew();
		}
		else
		{
			var iconGraphic:FlxGraphic = FlxG.bitmap.add(Paths.image('icons/icon-$id'), false);
			loadGraphic(iconGraphic, true, Std.int(iconGraphic.width * 0.5), iconGraphic.height);
			loadAnimationOld();
		}

		playAnimation(Idle);
	}

	function correctCharacterId(charId:Null<String>):String
	{
		if (charId == null)  return Constants.DEFAULT_HEALTH_ICON;

		if (!Paths.exists(Paths.image('icons/icon-$charId')))
		{
			FlxG.log.warn('No icon for character: $charId : using face instead!');
			return Constants.DEFAULT_HEALTH_ICON;
		}

		return charId;
	}

	function loadAnimationOld():Void
	{
		// Don't flip BF's icon here! That's done later.
		this.animation.add(Idle, [0], 0, false, false);
		this.animation.add(Losing, [1], 0, false, false);
		if (animation.numFrames >= 3)
		{
			this.animation.add(Winning, [2], 0, false, false);
		}
	}

	function loadAnimationNew():Void
	{
		this.animation.addByPrefix(Idle, Idle, 24, true);
		this.animation.addByPrefix(Winning, Winning, 24, true);
		this.animation.addByPrefix(Losing, Losing, 24, true);
		this.animation.addByPrefix(ToWinning, ToWinning, 24, false);
		this.animation.addByPrefix(ToLosing, ToLosing, 24, false);
		this.animation.addByPrefix(FromWinning, FromWinning, 24, false);
		this.animation.addByPrefix(FromLosing, FromLosing, 24, false);
	}
	
	public dynamic function updateAnim(health:Float)
	{
		switch (getCurrentAnimation())
		{
		  case Idle:
			if (health < LOSING_THRESHOLD)
				playAnimation(ToLosing, Losing);
			else if (health > WINNING_THRESHOLD)
				playAnimation(ToWinning, Winning);
			else
				playAnimation(Idle);
		  case Winning:
			if (health < WINNING_THRESHOLD)
				playAnimation(FromWinning, Idle);
			else
				playAnimation(Winning, Idle);
		  case Losing:
			if (health > LOSING_THRESHOLD) 
				playAnimation(FromLosing, Idle);
			else
				playAnimation(Losing, Idle);
		  case ToLosing:
			if (isAnimationFinished()) playAnimation(Losing, Idle);
		  case ToWinning:
			if (isAnimationFinished()) playAnimation(Winning, Idle);
		  case FromLosing | FromWinning:
			if (isAnimationFinished()) playAnimation(Idle);
		  default:
			playAnimation(Idle);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	public function configure(data:Null<HealthIconData>):Void
	{
		if (data == null)
		{
			this.char = Constants.DEFAULT_HEALTH_ICON;
			this.antialiasing = data.antialiasing;
			this.scale.set(1.0, 1.0);
			this.updateHitbox();
			this.offset.x = this.offset.y = 0.0;
			this.flipX = isPlayer;
		}
		else
		{
			this.char = data.id;
			this.antialiasing = data.antialiasing;
			this.scale.set(data.scale ?? 1.0, data.scale ?? 1.0);
			this.updateHitbox();
			this.offset.x = (data.offsets != null) ? data.offsets[0] : 0.0;
			this.offset.y = (data.offsets != null) ? data.offsets[1] : 0.0;
			this.flipX = data.flipX ?? isPlayer; // Face the OTHER way by default, since that is more common.
		}		
	}

	public function getCurrentAnimation():String
	{
		if (this.animation == null || this.animation.curAnim == null) return "";
		return this.animation.curAnim.name;
	}

	public function hasAnimation(id:String):Bool
	{
		if (this.animation == null) return false;
	  
		return this.animation.getByName(id) != null;
	}

	public function isAnimationFinished():Bool
		return this.animation.finished;

	public function playAnimation(name:String, fallback:String = null, restart = false):Void
	{
		if (hasAnimation(name))
		{
			this.animation.play(name, restart, false, 0);
			return;
		}
		
		// Play the fallback animation if the requested animation was not found
		if (fallback != null && hasAnimation(fallback))
		{
			this.animation.play(fallback, restart, false, 0);
			return;
		}		
	}
}

enum abstract HealthIconState(String) to String from String
{
	
  /**
   * Indicates the health icon is in the default animation.
   * Plays as long as health is between 20% and 80%.
   */
   public var Idle = 'idle';

   /**
	* Indicates the health icon is playing the Winning animation.
	* Plays as long as health is above 80%.
	*/
   public var Winning = 'winning';
 
   /**
	* Indicates the health icon is playing the Losing animation.
	* Plays as long as health is below 20%.
	*/
   public var Losing = 'losing';
 
   /**
	* Indicates that the health icon is transitioning between `idle` and `winning`.
	* The next animation will play once the current animation finishes.
	*/
   public var ToWinning = 'toWinning';
 
   /**
	* Indicates that the health icon is transitioning between `idle` and `losing`.
	* The next animation will play once the current animation finishes.
	*/
   public var ToLosing = 'toLosing';
 
   /**
	* Indicates that the health icon is transitioning between `winning` and `idle`.
	* The next animation will play once the current animation finishes.
	*/
   public var FromWinning = 'fromWinning';
 
   /**
	* Indicates that the health icon is transitioning between `losing` and `idle`.
	* The next animation will play once the current animation finishes.
	*/
   public var FromLosing = 'fromLosing';
}
