package meta.data;

class Scoring {
    public static function calculateRank(scoreData:Null<SaveScoreData>):Null<ScoringRank>
    {
        if (scoreData?.tallies.totalNotes == 0 || scoreData == null) return null;

        // we can return null here, meaning that the player hasn't actually played and finished the song (thus has no data)
        if (scoreData.tallies.totalNotes == 0) return null;
    
        // Perfect (Platinum) is a Sick Full Clear
        var isPerfectGold = scoreData.tallies.sick == scoreData.tallies.totalNotes;
        if (isPerfectGold) return ScoringRank.PERFECT_GOLD;
        
        var grade = (scoreData.tallies.sick + scoreData.tallies.good) / scoreData.tallies.totalNotes;
        // Clear % (including bad and shit). 1.00 is a full clear but not a full combo
        var clear = (scoreData.tallies.totalNotesHit) / scoreData.tallies.totalNotes;

        if (grade == Constants.RANK_PERFECT_THRESHOLD) 
            return ScoringRank.PERFECT;
        else if (grade >= Constants.RANK_EXCELLENT_THRESHOLD)
            return ScoringRank.EXCELLENT;
        else if (grade >= Constants.RANK_GREAT_THRESHOLD)
            return ScoringRank.GREAT;
        else if (grade >= Constants.RANK_GOOD_THRESHOLD)
            return ScoringRank.GOOD;
        else
            return ScoringRank.SHIT;
    }

    public static function getValue(rank:Null<ScoringRank>):Int
    {
      if (rank == null) return -1;
      switch (rank)
      {
        case PERFECT_GOLD:
          return 5;
        case PERFECT:
          return 4;
        case EXCELLENT:
          return 3;
        case GREAT:
          return 2;
        case GOOD:
          return 1;
        case SHIT:
          return 0;
        default:
          return -1;
      }
    }
}

enum abstract ScoringRank(String)
{
  var PERFECT_GOLD;
  var PERFECT;
  var EXCELLENT;
  var GREAT;
  var GOOD;
  var SHIT;

  // Yes, we really need a different function for each comparison operator.
  @:op(A > B) static function compareGT(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = Scoring.getValue(a);
    var temp2:Int = Scoring.getValue(b);

    return temp1 > temp2;
  }

  @:op(A >= B) static function compareGTEQ(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = Scoring.getValue(a);
    var temp2:Int = Scoring.getValue(b);

    return temp1 >= temp2;
  }

  @:op(A < B) static function compareLT(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = Scoring.getValue(a);
    var temp2:Int = Scoring.getValue(b);

    return temp1 < temp2;
  }

  @:op(A <= B) static function compareLTEQ(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = Scoring.getValue(a);
    var temp2:Int = Scoring.getValue(b);

    return temp1 <= temp2;
  }

  // @:op(A == B) isn't necessary!

  /**
   * Delay in seconds
   */
  public function getMusicDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
        // return 2.5;
        return 95 / 24;
      case EXCELLENT:
        return 0;
      case GREAT:
        return 5 / 24;
      case GOOD:
        return 3 / 24;
      case SHIT:
        return 2 / 24;
      default:
        return 3.5;
    }
  }

  public function getBFDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
        // return 2.5;
        return 95 / 24;
      case EXCELLENT:
        return 97 / 24;
      case GREAT:
        return 95 / 24;
      case GOOD:
        return 95 / 24;
      case SHIT:
        return 95 / 24;
      default:
        return 3.5;
    }
  }

  public function getFlashDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
        // return 2.5;
        return 129 / 24;
      case EXCELLENT:
        return 122 / 24;
      case GREAT:
        return 109 / 24;
      case GOOD:
        return 107 / 24;
      case SHIT:
        return 186 / 24;
      default:
        return 3.5;
    }
  }

  public function getHighscoreDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
        // return 2.5;
        return 140 / 24;
      case EXCELLENT:
        return 140 / 24;
      case GREAT:
        return 129 / 24;
      case GOOD:
        return 127 / 24;
      case SHIT:
        return 207 / 24;
      default:
        return 3.5;
    }
  }

  public function getFreeplayRankIconAsset():String
  {
    switch (abstract)
    {
      case PERFECT_GOLD:
        return 'PERFECTSICK';
      case PERFECT:
        return 'PERFECT';
      case EXCELLENT:
        return 'EXCELLENT';
      case GREAT:
        return 'GREAT';
      case GOOD:
        return 'GOOD';
      case SHIT:
        return 'LOSS';
      default:
        return 'LOSS';
    }
  }

  public function getHorTextAsset()
  {
    switch (abstract)
    {
      case PERFECT_GOLD:
        return 'menus/base/resultScreen/rankText/rankScrollPERFECT';
      case PERFECT:
        return 'menus/base/resultScreen/rankText/rankScrollPERFECT';
      case EXCELLENT:
        return 'menus/base/resultScreen/rankText/rankScrollEXCELLENT';
      case GREAT:
        return 'menus/base/resultScreen/rankText/rankScrollGREAT';
      case GOOD:
        return 'menus/base/resultScreen/rankText/rankScrollGOOD';
      case SHIT:
        return 'menus/base/resultScreen/rankText/rankScrollLOSS';
      default:
        return 'menus/base/resultScreen/rankText/rankScrollGOOD';
    }
  }

  public function getVerTextAsset()
  {
    switch (abstract)
    {
      case PERFECT_GOLD:
        return 'menus/base/resultScreen/rankText/rankTextPERFECT';
      case PERFECT:
        return 'menus/base/resultScreen/rankText/rankTextPERFECT';
      case EXCELLENT:
        return 'menus/base/resultScreen/rankText/rankTextEXCELLENT';
      case GREAT:
        return 'menus/base/resultScreen/rankText/rankTextGREAT';
      case GOOD:
        return 'menus/base/resultScreen/rankText/rankTextGOOD';
      case SHIT:
        return 'menus/base/resultScreen/rankText/rankTextLOSS';
      default:
        return 'menus/base/resultScreen/rankText/rankTextGOOD';
    }
  }
}