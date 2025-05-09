WITH EligibleWins AS (
    SELECT 
        bs.BowlerID,
        b.BowlerFirstName,
        b.BowlerLastName,
        bs.MatchID,
        bs.GameNumber,
        bs.HandiCapScore,
        t.TourneyDate,
        t.TourneyLocation
    FROM Bowler_Scores        AS bs
    JOIN Tourney_Matches      AS tm ON tm.MatchID  = bs.MatchID
    JOIN Tournaments          AS t  ON t.TourneyID = tm.TourneyID
    JOIN Bowlers              AS b  ON b.BowlerID  = bs.BowlerID
    WHERE bs.WonGame = 1
      AND bs.HandiCapScore <= 190
      AND t.TourneyLocation IN ('Thunderbird Lanes',
                                'Totem Lanes',
                                'Bolero Lanes')
),
QualifiedBowlers AS (
    SELECT BowlerID
    FROM   EligibleWins
    GROUP  BY BowlerID
    HAVING COUNT(DISTINCT TourneyLocation) = 3          -- has wins at all three venues
)
SELECT 
    ew.BowlerID,
    ew.BowlerFirstName,
    ew.BowlerLastName,
    ew.MatchID       AS MatchNumber,
    ew.GameNumber,
    ew.HandiCapScore,
    ew.TourneyDate,
    ew.TourneyLocation
FROM   EligibleWins      AS ew
JOIN   QualifiedBowlers  AS qb USING (BowlerID)
ORDER  BY ew.BowlerID, ew.TourneyDate, ew.MatchID, ew.GameNumber;