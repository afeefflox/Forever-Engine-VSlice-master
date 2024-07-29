package meta;

import lime.utils.Assets;
import meta.state.PlayState;

using StringTools;

#if sys
import sys.FileSystem;
#end

class CoolUtil
{
	public static var difficultyLength = Constants.DEFAULT_DIFFICULTY_LIST.length;

	public static inline function difficultyFromNumber(number:Int):String
	{
		return Constants.DEFAULT_DIFFICULTY_LIST[number];
	}

	public static inline function dashToSpace(string:String):String
	{
		return string.replace("-", " ");
	}

	public static inline function spaceToDash(string:String):String
	{
		return string.replace(" ", "-");
	}

	public static inline function swapSpaceDash(string:String):String
	{
		return string.contains('-') ? dashToSpace(string) : spaceToDash(string);
	}

	public static inline function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = Assets.getText(path).trim().split('\n');
		for (i in 0...daList.length)
			daList[i] = daList[i].trim();
		return daList;
	}

	public static inline function getOffsetsFromTxt(path:String):Array<Array<String>>
	{
		var fullText:String = Assets.getText(path);
		var firstArray:Array<String> = fullText.split('\n');
		var swagOffsets:Array<Array<String>> = [];

		for (i in firstArray)
			swagOffsets.push(i.split(' '));

		return swagOffsets;
	}

	public static inline function returnAssetsLibrary(library:String, ?subDir:String = 'assets/images'):Array<String>
	{
		var libraryArray:Array<String> = [];

		#if sys
		var unfilteredLibrary = FileSystem.readDirectory('$subDir/$library');

		for (folder in unfilteredLibrary)
		{
			if (!folder.contains('.'))
				libraryArray.push(folder);
		}
		//trace(libraryArray);
		#end

		return libraryArray;
	}

	public static inline function getAnimsFromTxt(path:String):Array<Array<String>>
	{
		var fullText:String = Assets.getText(path);
		var firstArray:Array<String> = fullText.split('\n');
		var swagOffsets:Array<Array<String>> = [];

		for (i in firstArray)
			swagOffsets.push(i.split('--'));
		return swagOffsets;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		return [for (i in min...max) i];
	}

	public static function buildVoiceList(SONG:SwagSong):Array<String>
	{
		var suffix:String = (SONG.variation != null && SONG.variation != '' && SONG.variation != 'default') ? '-${SONG.variation}' : '';

		var playerId:String = SONG.characters[0];
		var voicePlayer:String = Paths.songPaths(SONG.song, 'Voices', '-$playerId$suffix');
		while (voicePlayer != null && !Paths.exists(voicePlayer, SOUND))
		{
		  // Remove the last suffix.
		  // For example, bf-car becomes bf.
		  playerId = playerId.split('-').slice(0, -1).join('-');
		  // Try again.
		  voicePlayer = playerId == '' ? null : Paths.songPaths(SONG.song, 'Voices', '-${playerId}$suffix');
		}
		if (voicePlayer == null)
		{
		  // Try again without $suffix.
		  playerId = SONG.characters[0];
		  voicePlayer = Paths.songPaths(SONG.song, 'Voices', '-$playerId');
		  while (voicePlayer != null && !Paths.exists(voicePlayer, SOUND))
		  {
			// Remove the last suffix.
			playerId = playerId.split('-').slice(0, -1).join('-');
			// Try again.
			

			voicePlayer = playerId == '' ? null : Paths.songPaths(SONG.song, 'Voices', '-${playerId}$suffix');
		  }
		}
	
		var opponentId:String = SONG.characters[1];
		var voiceOpponent:String = Paths.songPaths(SONG.song, 'Voices', '-${opponentId}$suffix');
		while (voiceOpponent != null && !Paths.exists(voiceOpponent, SOUND))
		{
		  // Remove the last suffix.
		  opponentId = opponentId.split('-').slice(0, -1).join('-');
		  // Try again.
		  voiceOpponent = opponentId == '' ? null : Paths.songPaths(SONG.song, 'Voices', '-${opponentId}$suffix');
		}
		if (voiceOpponent == null)
		{
		  // Try again without $suffix.
		  opponentId = SONG.characters[1];
		  voiceOpponent = Paths.songPaths(SONG.song, 'Voices', '-${opponentId}');
		  while (voiceOpponent != null && !Paths.exists(voiceOpponent, SOUND))
		  {
			// Remove the last suffix.
			opponentId = opponentId.split('-').slice(0, -1).join('-');
			// Try again.
			voiceOpponent = opponentId == '' ? null : Paths.songPaths(SONG.song, 'Voices', '-${opponentId}$suffix');
		  }
		}
	
		var result:Array<String> = [];
		if (voicePlayer != null) result.push(voicePlayer);
		if (voiceOpponent != null) result.push(voiceOpponent);
		if(voicePlayer == null && Paths.exists(Paths.songPaths(SONG.song, 'Voices', 'bf$suffix'), SOUND)) result.push(Paths.songPaths(SONG.song, 'Voices', '-bf$suffix'));
		if(voiceOpponent == null && Paths.exists(Paths.songPaths(SONG.song, 'Voices', 'dad$suffix'), SOUND)) result.push(Paths.songPaths(SONG.song, 'Voices', '-dad$suffix'));

		return result;
	}
}
