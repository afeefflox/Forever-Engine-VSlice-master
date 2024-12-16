package meta.data;

class Song implements IPlayStateScriptedClass implements IRegistryEntry<SongMetadata>
{
	public static final DEFAULT_SONGNAME:String = 'Unknown';
	public static final DEFAULT_ARTIST:String = 'Unknown';
	public static final DEFAULT_TIMEFORMAT:SongTimeFormat = SongTimeFormat.MILLISECONDS;
	public static final DEFAULT_DIVISIONS:Null<Int> = null;
	public static final DEFAULT_LOOPED:Bool = false;
	public static final DEFAULT_STAGE:String = 'stage';
	public static final DEFAULT_SCROLLSPEED:Float = 1.0;

	public final id:String;
	public final _data:Null<SongMetadata>;

	final _metadata:Map<String, SongMetadata>;
	final difficulties:Map<String, Map<String, SongDifficulty>>;
	public var variations(get, never):Array<String>;

	function get_variations():Array<String>  return _metadata.keys().array();
	public var validScore:Bool = true;

	public var songName(get, never):String;

	function get_songName():String
	{
		if (_data != null) return _data?.songName ?? DEFAULT_SONGNAME;
		if (_metadata.size() > 0) return _metadata.get(Constants.DEFAULT_VARIATION)?.songName ?? DEFAULT_SONGNAME;
		return DEFAULT_SONGNAME;	
	}

	public var songCharacter(get, never):String;
	function get_songCharacter():String
	{
		if (_data.playData.characters.opponent != null) return _data?.playData?.characters?.opponent ?? 'bf';
		if (_metadata.size() > 0) return _metadata.get(Constants.DEFAULT_VARIATION)?.playData?.characters?.opponent ?? 'bf';
		return 'bf';	
	}

	public var songArtist(get, never):String;

	function get_songArtist():String
	{
		
		if (_data != null) return _data?.artist ?? DEFAULT_ARTIST;
		if (_metadata.size() > 0) return _metadata.get(Constants.DEFAULT_VARIATION)?.artist ?? DEFAULT_ARTIST;
		return DEFAULT_ARTIST;
	}

	public var charter(get, never):String;

	function get_charter():String
	{
		if (_data != null) return _data?.charter ?? 'Unknown';
		if (_metadata.size() > 0) return _metadata.get(Constants.DEFAULT_VARIATION)?.charter ?? 'Unknown';
		return Constants.DEFAULT_CHARTER;
	}

	public function new(id:String)
	{
		this.id = id;

		difficulties = new Map<String, Map<String, SongDifficulty>>();

		_data = _fetchData(id);
		_metadata = _data == null ? [] : [Constants.DEFAULT_VARIATION => _data];
	
		if (_data != null && _data.playData != null)
		{
			for (vari in _data.playData.songVariations)
			{
				if (!validateVariationId(vari))
				{
					trace('  [WARN] Variation id "$vari" is invalid, skipping...');
					continue;
				}

				var variMeta:Null<SongMetadata> = fetchVariationMetadata(id, vari);
				if (variMeta != null)
				{
					_metadata.set(variMeta.variation, variMeta);
					trace('  Loaded variation: $vari');
				}
				else
				{
					FlxG.log.warn('[SONG] Failed to load variation metadata (${id}:${vari}), is the path correct?');
					trace('  FAILED to load variation: $vari');
				}
			}
		}

		if (_metadata.size() == 0)
		{
			trace('[WARN] Could not find song data for songId: $id');
			return;
		}
		populateDifficulties();
	}

	public static function buildRaw(songId:String, metadata:Array<SongMetadata>, variations:Array<String>, charts:Map<String, SongChartData>,
		includeScript:Bool = true, validScore:Bool = false):Song
	{
		@:privateAccess
		var result:Null<Song>;
	
		if (includeScript && SongRegistry.instance.isScriptedEntry(songId))
		{
		  var songClassName:String = SongRegistry.instance.getScriptedEntryClassName(songId);
	
		  @:privateAccess
		  result = SongRegistry.instance.createScriptedEntry(songClassName);
		}
		else
		{
		  @:privateAccess
		  result = SongRegistry.instance.createEntry(songId);
		}

		if (result == null) throw 'ERROR: Could not build Song instance ($songId), is the attached script bad?';

		result._metadata.clear();
		for (meta in metadata) result._metadata.set(meta.variation, meta);

		result.difficulties.clear();
		result.populateDifficulties();
	
		for (variation => chartData in charts) result.applyChartData(chartData, variation);

		result.validScore = validScore;

		return result;
	}

	public function getRawMetadata():Array<SongMetadata>    return _metadata.values();

	public function listAlbums(variation:String):Map<String, String>
	{
		var result:Map<String, String> = new Map<String, String>();

		for (variationMap in difficulties)
		{
		  for (difficultyId in variationMap.keys())
		  {
			var meta:Null<SongDifficulty> = variationMap.get(difficultyId);
			if (meta != null && meta.album != null)
			{
			  result.set(difficultyId, meta.album);
			}
		  }
		}
		return result;
	}

	public function getAlbumId(diffId:String, variation:String):String
	{
		var diff:Null<SongDifficulty> = getDifficulty(diffId, variation);
		if (diff == null) return '';
	
		return diff.album ?? '';
	}

	function populateDifficulties():Void
	{
		if (_metadata == null || _metadata.size() == 0) return;

		for (metadata in _metadata.values())
		{
			if (metadata == null || metadata.playData == null) continue;

			if (metadata.playData.difficulties.length == 0)
			{
				trace('[SONG] Warning: Song $id (variation ${metadata.variation}) has no difficulties listed in metadata!');
				continue;
			}

			var difficultyMap:Map<String, SongDifficulty> = new Map<String, SongDifficulty>();

			for (diffId in metadata.playData.difficulties)
			{
				var difficulty:SongDifficulty = new SongDifficulty(this, diffId, metadata.variation);

				difficulty.songName = metadata.songName;
				difficulty.songArtist = metadata.artist;
				difficulty.charter = metadata.charter ?? Constants.DEFAULT_CHARTER;
				difficulty.timeFormat = metadata.timeFormat;
				difficulty.divisions = metadata.divisions;
				difficulty.timeChanges = metadata.timeChanges;
				difficulty.looped = metadata.looped;
				difficulty.generatedBy = metadata.generatedBy;
				difficulty.offsets = metadata?.offsets ?? new SongOffsets();
		
				difficulty.difficultyRating = metadata.playData.ratings.get(diffId) ?? 0;
				difficulty.album = metadata.playData.album;
		
				difficulty.stage = metadata.playData.stage;
				difficulty.noteStyle = metadata.playData.noteStyle;
		
				difficulty.characters = metadata.playData.characters;
				difficulty.previewStart = metadata.playData.previewStart;
				difficulty.previewEnd = metadata.playData.previewEnd;
				difficultyMap.set(diffId, difficulty);
			}
			difficulties.set(metadata.variation, difficultyMap);
		}
	}

	public function cacheCharts(force:Bool = false):Void
	{
		if (force) clearCharts();

		trace('Caching ${variations.length} chart files for song $id');
		for (variation in variations)
		{
			var version:Null<thx.semver.Version> = SongRegistry.instance.fetchEntryChartVersion(id, variation);
			if (version == null) continue;
			var chart:Null<SongChartData> = SongRegistry.instance.parseEntryChartDataWithMigration(id, variation, version);
			if (chart == null) continue;
			applyChartData(chart, variation);
		}
		trace('Done caching charts.');
	}

	function applyChartData(chartData:SongChartData, variation:String):Void
	{
		for (diffId in chartData.notes.keys())
		{
			var nullDiff:Null<SongDifficulty> = getDifficulty(diffId, variation);
			var difficulty:SongDifficulty = nullDiff ?? new SongDifficulty(this, diffId, variation);
	  
			if (nullDiff == null)
			{
				trace('Fabricated new difficulty for $diffId.');
				var metadata = _metadata.get(variation);
				difficulties.get(variation)?.set(diffId, difficulty);
		
				if (metadata != null)
				{
					difficulty.songName = metadata.songName;
					difficulty.songArtist = metadata.artist;
					difficulty.charter = metadata.charter ?? Constants.DEFAULT_CHARTER;
					difficulty.timeFormat = metadata.timeFormat;
					difficulty.divisions = metadata.divisions;
					difficulty.timeChanges = metadata.timeChanges;
					difficulty.looped = metadata.looped;
					difficulty.generatedBy = metadata.generatedBy;
					difficulty.offsets = metadata?.offsets ?? new SongOffsets();
		  
					difficulty.stage = metadata.playData.stage;
					difficulty.noteStyle = metadata.playData.noteStyle;
					difficulty.characters = metadata.playData.characters;
				}
			}
			difficulty.notes = chartData.getNotes(diffId) ?? [];
			difficulty.scrollSpeed = chartData.getScrollSpeed(diffId) ?? 1.0;
			difficulty.events = chartData.events;
		}
	}

	public function getDifficulty(?diffId:String, ?variation:String, ?variations:Array<String>):Null<SongDifficulty>
	{
		if (diffId == null) diffId = listDifficulties(variation, variations)[0];
		if (variation == null) variation = Constants.DEFAULT_VARIATION;
		if (variations == null) variations = [variation];

		for (currentVariation in variations)
		{
			if (difficulties.get(currentVariation)?.exists(diffId) ?? false) return difficulties.get(currentVariation)?.get(diffId);
		}
		return null;
	}

	public function getFirstValidVariation(?diffId:String, ?currentCharacter:PlayableCharacter, ?possibleVariations:Array<String>):Null<String>
	{
		if (possibleVariations == null) possibleVariations = getVariationsByCharacter(currentCharacter);
		if (diffId == null) diffId = listDifficulties(null, possibleVariations)[0];
		for (variationId in possibleVariations) if (difficulties.get('$variationId')?.exists(diffId) ?? false) return variationId;

		return null;
	}

	public function getVariationsByCharacter(?char:PlayableCharacter):Array<String>
	{
		if (char == null)
		{
			var result = variations;
			result.sort(SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_VARIATION_LIST));
			return result;
		}

		var result = [];
		for (variation in variations)
		{
			var metadata = _metadata.get(variation);

			var playerCharId = metadata?.playData?.characters?.player;
			if (playerCharId == null) continue;
	  
			if (char.shouldShowCharacter(playerCharId)) result.push(variation);
		}

		result.sort(SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_VARIATION_LIST));

		return result;
	}

	public function getVariationsByCharacterId(?charId:String):Array<String> return getVariationsByCharacter(PlayerRegistry.instance.fetchEntry(charId ?? ''));

	public function listDifficulties(?variationId:String, ?variationIds:Array<String>, showLocked:Bool = false, showHidden:Bool = false):Array<String>
	{
		if (variationIds == null) variationIds = [];
		if (variationId != null) variationIds.push(variationId);
	
		if (variationIds.length == 0) return [];
	
		var diffFiltered:Array<String> = variationIds.map(function(variationId:String):Array<String> {
		  var metadata = _metadata.get(variationId);
		  return metadata?.playData?.difficulties ?? [];
		}).flatten().filterNull().distinct();

		diffFiltered = diffFiltered.filter(function(diffId:String):Bool {
			if (showHidden) return true;
			for (targetVariation in variationIds) if (isDifficultyVisible(diffId, targetVariation)) return true;
			return false;
		});

		diffFiltered.sort(SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_DIFFICULTY_LIST_FULL));

		return diffFiltered;
	}

	public function listSuffixedDifficulties(variationIds:Array<String>, ?showLocked:Bool, ?showHidden:Bool):Array<String>
	{
		var result = [];

		for (variation in variationIds)
		{
		  var difficulties = listDifficulties(variation, null, showLocked, showHidden);
		  for (difficulty in difficulties)
		  {
			var suffixedDifficulty = (variation != Constants.DEFAULT_VARIATION
			  && variation != 'erect') ? '$difficulty-${variation}' : difficulty;
			result.push(suffixedDifficulty);
		  }
		}
	
		result.sort(SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_DIFFICULTY_LIST_FULL));
	
		return result;		
	}

	public function hasDifficulty(diffId:String, ?variationId:String, ?variationIds:Array<String>):Bool
	{
		if (variationIds == null) variationIds = [];
		if (variationId != null) variationIds.push(variationId);
	
		for (targetVariation in variationIds)
		{
		  if (difficulties.get(targetVariation)?.exists(diffId) ?? false) return true;
		}
		return false;
	}

	public function isDifficultyVisible(diffId:String, variationId:String):Bool
	{
		var variation = _metadata.get(variationId);
		if (variation == null) return false;
		return variation.playData.difficulties.contains(diffId);
	}

	public function listAltInstrumentalIds(difficultyId:String, variationId:String):Array<String>
	{
		var targetDifficulty:Null<SongDifficulty> = getDifficulty(difficultyId, variationId);
		if (targetDifficulty == null) return [];
	
		return targetDifficulty?.characters?.altInstrumentals ?? [];
	}

	public function getBaseInstrumentalId(difficultyId:String, variationId:String):String
	{
		var targetDifficulty:Null<SongDifficulty> = getDifficulty(difficultyId, variationId);
		if (targetDifficulty == null) return '';
	
		return targetDifficulty?.characters?.instrumental ?? '';
	}

	public function clearCharts():Void
	{
		for (variationMap in difficulties)
		{
			for (diff in variationMap) diff.clearChart();
		}
	}

	public function destroy():Void {}
	public function toString():String return 'Song($id)';
	public function onPause(event:PauseScriptEvent):Void {};
	public function onResume(event:ScriptEvent):Void {};
	public function onSongStart(event:ScriptEvent):Void {};
	public function onSongLoaded(event:SongLoadScriptEvent):Void {};
	public function onSongEnd(event:ScriptEvent):Void {};
	public function onGameOver(event:ScriptEvent):Void {};
	public function onSongRetry(event:ScriptEvent):Void {};
	public function onNoteIncoming(event:NoteScriptEvent) {}
	public function onNoteHit(event:HitNoteScriptEvent) {}
	public function onNoteMiss(event:NoteScriptEvent):Void {};
	public function onSustainHit(event:SustainScriptEvent) {};
	public function onNoteGhostMiss(event:GhostMissNoteScriptEvent):Void {};
	public function onStepHit(event:SongTimeScriptEvent):Void {};
	public function onBeatHit(event:SongTimeScriptEvent):Void {};
	public function onCountdownStart(event:CountdownScriptEvent):Void {};
	public function onCountdownStep(event:CountdownScriptEvent):Void {};
	public function onCountdownEnd(event:CountdownScriptEvent):Void {};
	public function onScriptEvent(event:ScriptEvent):Void {};
	public function onCreate(event:ScriptEvent):Void {};
	public function onDestroy(event:ScriptEvent):Void {};  
	public function onUpdate(event:UpdateScriptEvent):Void {};
	public function onSongEvent(event:SongEventScriptEvent):Void {};

	static function _fetchData(id:String):Null<SongMetadata>
	{
		trace('Fetching song metadata for $id');
		var version:Null<thx.semver.Version> = SongRegistry.instance.fetchEntryMetadataVersion(id);
		if (version == null) return null;
		return SongRegistry.instance.parseEntryMetadataWithMigration(id, Constants.DEFAULT_VARIATION, version);
	}

	function fetchVariationMetadata(id:String, vari:String):Null<SongMetadata>
	{
		var version:Null<thx.semver.Version> = SongRegistry.instance.fetchEntryMetadataVersion(id, vari);
		if (version == null) return null;
		var meta:Null<SongMetadata> = SongRegistry.instance.parseEntryMetadataWithMigration(id, vari, version);
		return meta;
	}

	static final VARIATION_REGEX = ~/^[a-z][a-z0-9]+$/;

	static function validateVariationId(variation:String):Bool
	{
		if (Constants.DEFAULT_VARIATION_LIST.contains(variation)) return true;
		return VARIATION_REGEX.match(variation);
	}
}

class SongDifficulty
{
	public final song:Song;
	public final difficulty:String;
	public final variation:String;
	public var notes:Array<SongNoteData>;
	public var scrollSpeed:Float = Constants.DEFAULT_SCROLLSPEED;
	public var events:Array<SongEventData>;

	public var songName:String = Constants.DEFAULT_SONGNAME;
	public var songArtist:String = Constants.DEFAULT_ARTIST;
	public var charter:String = Constants.DEFAULT_CHARTER;
	public var timeFormat:SongTimeFormat = 'ms';
	public var divisions:Null<Int> = null;
	public var looped:Bool = false;
	public var offsets:SongOffsets = new SongOffsets();
	public var generatedBy:String = SongRegistry.DEFAULT_GENERATEDBY;
	public var timeChanges:Array<SongTimeChange> = [];
	public var previewStart:Float = 0.0;
	public var previewEnd:Float = 0.0;

	public var stage:String = Constants.DEFAULT_STAGE;
	public var noteStyle:String = Constants.DEFAULT_NOTE_STYLE;
	public var characters:SongCharacterData = null;

	public var difficultyRating:Int = 0;
	public var album:Null<String> = null;

	public function new(song:Song, diffId:String, variation:String)
	{
		this.song = song;
		this.difficulty = diffId;
		this.variation = variation;
	}

	public function clearChart():Void   notes = null;

	public function getStartingBPM():Float
	{
		if (timeChanges.length == 0) return 0;
		return timeChanges[0].bpm;
	}

	public function getInstPath(instrumental = ''):String
	{
		if (characters != null)
		{
			if (instrumental != '' && characters.altInstrumentals.contains(instrumental))
				return Paths.inst(this.song.id, '-$instrumental');
			else
				return Paths.inst(this.song.id, (characters.instrumental ?? '') != '' ? '-${characters.instrumental}' : '');				
		}
		else
			return Paths.inst(this.song.id);
	}

	public function cacheInst(instrumental = ''):Void FlxG.sound.cache(getInstPath(instrumental));

	public function playInst(volume:Float = 1.0, instId:String = '', looped:Bool = false):Void
	{
		var suffix:String = (instId != '') ? '-$instId' : '';

		FlxG.sound.music = FunkinSound.load(Paths.inst(this.song.id, suffix), volume, looped, false, true);
		FlxG.sound.list.remove(FlxG.sound.music);
	}

	public function cacheVocals():Void
	{
		for (voice in buildVoiceList())
		{
			trace('Caching vocal track: $voice');
			FlxG.sound.cache(voice);
		}
	}

	public function buildVoiceList():Array<String>
	{
		var result:Array<String> = [];
		result = result.concat(buildPlayerVoiceList());
		result = result.concat(buildOpponentVoiceList());
		if (result.length == 0)
		{
		  var suffix:String = (variation != null && variation != '' && variation != 'default') ? '-$variation' : '';
		  // Try to use `Voices.ogg` if no other voices are found.
		  if (Assets.exists(Paths.voices(this.song.id, ''))) result.push(Paths.voices(this.song.id, '$suffix'));
		}
		return result;		
	}

	public function buildPlayerVoiceList():Array<String>
	{
		var suffix:String = (variation != null && variation != '' && variation != 'default') ? '-$variation' : '';
		if (characters.playerVocals == null)
		{
			var playerId:String = characters.player;
			var playerVoice:String = Paths.voices(this.song.id, '-${playerId}$suffix');
	  
			while (playerVoice != null && !Assets.exists(playerVoice))
			{
				playerId = playerId.split('-').slice(0, -1).join('-');
				playerVoice = playerId == '' ? null : Paths.voices(this.song.id, '-${playerId}$suffix');
			}
			if (playerVoice == null)
			{
				playerId = characters.player;
				playerVoice = Paths.voices(this.song.id, '-${playerId}');
				while (playerVoice != null && !Assets.exists(playerVoice))
				{
					playerId = playerId.split('-').slice(0, -1).join('-');
					playerVoice = playerId == '' ? null : Paths.voices(this.song.id, '-${playerId}$suffix');
				}
			}
			return playerVoice != null ? [playerVoice] : ['bf'];
		}
		else
		{
			var playerIds:Array<String> = characters?.playerVocals ?? [characters.player];
			var playerVoices:Array<String> = playerIds.map((id) -> Paths.voices(this.song.id, '-$id$suffix'));
			return playerVoices;
		}
	}

	public function buildOpponentVoiceList():Array<String>
	{
		var suffix:String = (variation != null && variation != '' && variation != 'default') ? '-$variation' : '';
		if (characters.opponentVocals == null)
		{
			var opponentId:String = characters.opponent;
			var opponentVoice:String = Paths.voices(this.song.id, '-${opponentId}$suffix');
			while (opponentVoice != null && !Assets.exists(opponentVoice))
			{
				opponentId = opponentId.split('-').slice(0, -1).join('-');
				opponentVoice = opponentId == '' ? null : Paths.voices(this.song.id, '-${opponentId}$suffix');
			}
			if (opponentVoice == null)
			{
				opponentId = characters.opponent;
				opponentVoice = Paths.voices(this.song.id, '-${opponentId}');
				while (opponentVoice != null && !Assets.exists(opponentVoice))
				{
					opponentId = opponentId.split('-').slice(0, -1).join('-');
					opponentVoice = opponentId == '' ? null : Paths.voices(this.song.id, '-${opponentId}$suffix');
				}
			}
			return opponentVoice != null ? [opponentVoice] : ['dad'];
		}
		else
		{
			var opponentIds:Array<String> = characters?.opponentVocals ?? [characters.opponent];
			var opponentVoices:Array<String> = opponentIds.map((id) -> Paths.voices(this.song.id, '-$id$suffix'));
	  
			return opponentVoices;
		}
	}

	public function buildVocals(?instId:String = ''):VoicesGroup
	{
		var result:VoicesGroup = new VoicesGroup();

		var playerVoiceList:Array<String> = this.buildPlayerVoiceList();
		var opponentVoiceList:Array<String> = this.buildOpponentVoiceList();

		for (playerVoice in playerVoiceList) result.addPlayerVoice(FunkinSound.load(playerVoice));
		for (opponentVoice in opponentVoiceList) result.addOpponentVoice(FunkinSound.load(opponentVoice));
		
		result.playerVoicesOffset = offsets.getVocalOffset(characters.player, instId);
		result.opponentVoicesOffset = offsets.getVocalOffset(characters.opponent, instId);
	
		return result;
	}
}