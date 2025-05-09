WITH qualifying_games AS (
    /* 1.  Games that meet all row‑level requirements */
    SELECT
        bs.BowlerID,
        bs.MatchID,
        bs.GameNumber,
        bs.HandiCapScore,
        t.TourneyDate,
        t.TourneyLocation
    FROM Bowler_Scores       AS bs
    JOIN Tourney_Matches     AS tm ON tm.MatchID  = bs.MatchID
    JOIN Tournaments         AS t  ON t.TourneyID = tm.TourneyID
    WHERE bs.WonGame = 1
      AND bs.HandiCapScore <= 190
      AND t.TourneyLocation IN ('Thunderbird Lanes',
                                'Totem Lanes',
                                'Bolero Lanes')
),
qualified_bowlers AS (
    /* 2.  Bowlers who have such a win at *all three* venues */
    SELECT BowlerID
    FROM qualifying_games
    GROUP BY BowlerID
    HAVING COUNT(DISTINCT TourneyLocation) = 3
)

SELECT
    b.BowlerID        AS BowlerID,
    b.BowlerFirstName AS FirstName,
    b.BowlerLastName  AS LastName,
    q.MatchID         AS MatchNumber,
    q.GameNumber      AS GameNumber,
    q.HandiCapScore   AS HandicapScore,
    q.TourneyDate     AS TourneyDate,
    q.TourneyLocation AS TourneyLocation
FROM qualifying_games  AS q
JOIN qualified_bowlers AS qb ON qb.BowlerID = q.BowlerID
JOIN Bowlers           AS b  ON b.BowlerID  = q.BowlerID
ORDER BY
    b.BowlerLastName,
    b.BowlerFirstName,
    q.TourneyDate,
    q.MatchID,
    q.GameNumber;