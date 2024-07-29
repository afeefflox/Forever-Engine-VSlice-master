package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import gameObjects.userInterface.*;
import gameObjects.userInterface.menu.*;
import gameObjects.userInterface.notes.*;
import gameObjects.userInterface.notes.Strumline.UIStaticArrow;
import meta.data.Conductor;
import meta.data.Timings;
import meta.state.PlayState;

using StringTools;

/**
	Forever Assets is a class that manages the different asset types, basically a compilation of switch statements that are
	easy to edit for your own needs. Most of these are just static functions that return information
**/
class ForeverAssets
{
	//
	public static function generateCombo(asset:String, number:String, allSicks:Bool, assetModifier:String = 'base', changeableSkin:String = 'default',
			baseLibrary:String, negative:Bool, createdColor:FlxColor, scoreInt:Int):FlxSprite
	{
		var width = 100;
		var height = 140;

		if (assetModifier == 'pixel')
		{
			width = 10;
			height = 12;
		}
		var newSprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ForeverTools.returnSkinAsset(asset, assetModifier, changeableSkin, baseLibrary)),
			true, width, height);
		switch (assetModifier)
		{
			default:
				newSprite.alpha = 1;
				newSprite.screenCenter();
				newSprite.x += (43 * scoreInt) + 20;
				newSprite.y += 60;

				newSprite.color = FlxColor.WHITE;
				if (negative)
					newSprite.color = createdColor;

				newSprite.animation.add('base', [
					(Std.parseInt(number) != null ? Std.parseInt(number) + 1 : 0) + (!allSicks ? 0 : 11)
				], 0, false);
				newSprite.animation.play('base');
		}

		if (assetModifier == 'pixel')
			newSprite.setGraphicSize(Std.int(newSprite.width * PlayState.daPixelZoom));
		else
		{
			newSprite.antialiasing = true;
			newSprite.setGraphicSize(Std.int(newSprite.width * 0.5));
		}
		newSprite.updateHitbox();
		if (!Init.trueSettings.get('Simply Judgements'))
		{
			newSprite.acceleration.y = FlxG.random.int(200, 300);
			newSprite.velocity.y = -FlxG.random.int(140, 160);
			newSprite.velocity.x = FlxG.random.float(-5, 5);
		}

		return newSprite;
	}

	public static function generateRating(asset:String, perfectSick:Bool, timing:String, assetModifier:String = 'base', changeableSkin:String = 'default',
			baseLibrary:String):FlxSprite
	{
		var width = 500;
		var height = 163;
		if (assetModifier == 'pixel')
		{
			width = 72;
			height = 32;
		}
		var rating:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ForeverTools.returnSkinAsset('judgements', assetModifier, changeableSkin,
			baseLibrary)), true, width, height);
		switch (assetModifier)
		{
			default:
				rating.alpha = 1;
				rating.screenCenter();
				rating.x = (FlxG.width * 0.55) - 40;
				rating.y -= 60;
				if (!Init.trueSettings.get('Simply Judgements'))
				{
					rating.acceleration.y = 550;
					rating.velocity.y = -FlxG.random.int(140, 175);
					rating.velocity.x = -FlxG.random.int(0, 10);
				}
				rating.animation.add('base', [
					Std.int((Timings.judgementsMap.get(asset)[0] * 2) + (perfectSick ? 0 : 2) + (timing == 'late' ? 1 : 0))
				], 24, false);
				rating.animation.play('base');
		}

		if (assetModifier == 'pixel')
			rating.setGraphicSize(Std.int(rating.width * PlayState.daPixelZoom * 0.7));
		else
		{
			rating.antialiasing = true;
			rating.setGraphicSize(Std.int(rating.width * 0.7));
		}

		return rating;
	}
	/**
		Notes!
	**/
	public static function generateArrow(assetModifier, strumTime, noteData, ?noteType:String = "", ?isSustainNote:Bool = false, ?prevNote:Note = null):Note
	{
		var newNote:Note;
		var changeableSkin:String = Init.trueSettings.get("Note Skin");
		// gonna improve the system eventually
		if (changeableSkin.startsWith('quant'))
			newNote = Note.returnQuantNote(assetModifier, strumTime, noteData, noteType, isSustainNote, prevNote);
		else
			newNote = Note.returnDefaultNote(assetModifier, strumTime, noteData, noteType, isSustainNote, prevNote);
		return newNote;
	}

	/**
		Checkmarks!
	**/
	public static function generateCheckmark(x:Float, y:Float, asset:String, assetModifier:String = 'base', changeableSkin:String = 'default',
			baseLibrary:String)
	{
		var newCheckmark:Checkmark = new Checkmark(x, y);
		switch (assetModifier)
		{
			default:
				newCheckmark.frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset(asset, assetModifier, changeableSkin, baseLibrary));
				newCheckmark.antialiasing = true;

				newCheckmark.animation.addByPrefix('false finished', 'uncheckFinished');
				newCheckmark.animation.addByPrefix('false', 'uncheck', 12, false);
				newCheckmark.animation.addByPrefix('true finished', 'checkFinished');
				newCheckmark.animation.addByPrefix('true', 'check', 12, false);
				newCheckmark.setGraphicSize(Std.int(newCheckmark.width * 0.7));
				newCheckmark.updateHitbox();

				///*
				var offsetByX = 45;
				var offsetByY = 5;
				newCheckmark.addOffset('false', offsetByX, offsetByY);
				newCheckmark.addOffset('true', offsetByX, offsetByY);
				newCheckmark.addOffset('true finished', offsetByX, offsetByY);
				newCheckmark.addOffset('false finished', offsetByX, offsetByY);
		}
		return newCheckmark;
	}
}
