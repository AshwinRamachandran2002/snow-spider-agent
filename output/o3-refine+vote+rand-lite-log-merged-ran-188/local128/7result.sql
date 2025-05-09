WITH Base AS (
    SELECT 
        bs.BowlerID,
        bs.MatchID,
        bs.GameNumber,
        bs.HandiCapScore,
        t.TourneyDate,
        t.TourneyLocation
    FROM Bowler_Scores      AS bs
    JOIN Tourney_Matches    AS tm ON tm.MatchID   = bs.MatchID
    JOIN Tournaments        AS t  ON t.TourneyID  = tm.TourneyID
    WHERE bs.WonGame = 1
      AND bs.HandiCapScore <= 190
      AND t.TourneyLocation IN ('Thunderbird Lanes','Totem Lanes','Bolero Lanes')
),
QualifiedBowlers AS (
    SELECT BowlerID
    FROM Base
    GROUP BY BowlerID
    HAVING COUNT(DISTINCT TourneyLocation) = 3     -- must have at least one win at each venue
)
SELECT
    b.BowlerID,
    b.BowlerFirstName,
    b.BowlerLastName,
    base.MatchID,
    base.GameNumber,
    base.HandiCapScore,
    base.TourneyDate,
    base.TourneyLocation
FROM Base              AS base
JOIN QualifiedBowlers  AS q   ON q.BowlerID = base.BowlerID
JOIN Bowlers           AS b   ON b.BowlerID = base.BowlerID
ORDER BY 
    b.BowlerLastName,
    b.BowlerFirstName,
    base.TourneyDate,
    base.MatchID,
    base.GameNumber;