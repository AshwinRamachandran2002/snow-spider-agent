WITH qualified_bowlers AS (
    SELECT bs.BowlerID
    FROM   Bowler_Scores      AS bs
    JOIN   Tourney_Matches    AS tm  ON tm.MatchID  = bs.MatchID
    JOIN   Tournaments        AS t   ON t.TourneyID = tm.TourneyID
    WHERE  bs.WonGame = 1
      AND  bs.HandiCapScore <= 190
      AND  t.TourneyLocation IN ('Thunderbird Lanes',
                                 'Totem Lanes',
                                 'Bolero Lanes')
    GROUP BY bs.BowlerID
    HAVING COUNT(DISTINCT t.TourneyLocation) = 3        -- must have a win ≤190 at all three venues
)

SELECT
    b.BowlerID,
    b.BowlerFirstName,
    b.BowlerLastName,
    bs.MatchID          AS MatchNumber,
    bs.GameNumber,
    bs.HandiCapScore,
    t.TourneyDate,
    t.TourneyLocation
FROM   Bowler_Scores      AS bs
JOIN   qualified_bowlers  AS qb ON qb.BowlerID = bs.BowlerID
JOIN   Tourney_Matches    AS tm ON tm.MatchID  = bs.MatchID
JOIN   Tournaments        AS t  ON t.TourneyID = tm.TourneyID
JOIN   Bowlers            AS b  ON b.BowlerID  = bs.BowlerID
WHERE  bs.WonGame = 1
  AND  bs.HandiCapScore <= 190
  AND  t.TourneyLocation IN ('Thunderbird Lanes',
                             'Totem Lanes',
                             'Bolero Lanes')
ORDER BY
    b.BowlerLastName,
    b.BowlerFirstName,
    t.TourneyDate,
    bs.MatchID,
    bs.GameNumber;