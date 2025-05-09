WITH WonGames AS (
    SELECT
        bs.BowlerID,
        b.BowlerFirstName,
        b.BowlerLastName,
        bs.MatchID,
        bs.GameNumber,
        bs.HandiCapScore,
        t.TourneyDate,
        t.TourneyLocation
    FROM Bowler_Scores            AS bs
    JOIN Tourney_Matches          AS tm ON tm.MatchID  = bs.MatchID
    JOIN Tournaments              AS t  ON t.TourneyID = tm.TourneyID
    JOIN Bowlers                  AS b  ON b.BowlerID  = bs.BowlerID
    WHERE bs.WonGame = 1
      AND bs.HandiCapScore <= 190
      AND t.TourneyLocation IN ('Thunderbird Lanes',
                                'Totem Lanes',
                                'Bolero Lanes')
),
EligibleBowlers AS (
    SELECT BowlerID
    FROM WonGames
    GROUP BY BowlerID
    HAVING COUNT(DISTINCT TourneyLocation) = 3   -- must have a qualifying win at all three venues
)
SELECT
    wg.BowlerID,
    wg.BowlerFirstName,
    wg.BowlerLastName,
    wg.MatchID,
    wg.GameNumber,
    wg.HandiCapScore,
    wg.TourneyDate,
    wg.TourneyLocation
FROM WonGames        AS wg
JOIN EligibleBowlers AS eb USING (BowlerID)
ORDER BY
    wg.BowlerLastName,
    wg.BowlerFirstName,
    wg.TourneyDate,
    wg.MatchID,
    wg.GameNumber;