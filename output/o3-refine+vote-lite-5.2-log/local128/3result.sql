WITH QualifiedWins AS (
    SELECT
        bs.BowlerID,
        bs.MatchID,
        bs.GameNumber,
        bs.HandiCapScore,
        t.TourneyDate,
        t.TourneyLocation
    FROM Bowler_Scores        AS bs
    JOIN Tourney_Matches      AS tm ON tm.MatchID  = bs.MatchID
    JOIN Tournaments          AS t  ON t.TourneyID = tm.TourneyID
    WHERE bs.WonGame = 1
      AND bs.HandiCapScore <= 190
      AND t.TourneyLocation IN ('Thunderbird Lanes',
                                'Totem Lanes',
                                'Bolero Lanes')
),
QualifyingBowlers AS (
    SELECT BowlerID
    FROM QualifiedWins
    GROUP BY BowlerID
    HAVING COUNT(DISTINCT TourneyLocation) = 3        -- won at all three venues
)
SELECT
    b.BowlerID,
    b.BowlerFirstName,
    b.BowlerLastName,
    qw.MatchID,
    qw.GameNumber,
    qw.HandiCapScore,
    qw.TourneyDate,
    qw.TourneyLocation
FROM QualifiedWins   AS qw
JOIN QualifyingBowlers AS qb ON qb.BowlerID = qw.BowlerID
JOIN Bowlers           AS b  ON b.BowlerID = qw.BowlerID
ORDER BY
    b.BowlerID,
    qw.TourneyDate,
    qw.MatchID,
    qw.GameNumber;