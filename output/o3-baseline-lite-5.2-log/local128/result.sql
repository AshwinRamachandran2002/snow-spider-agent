WITH qualified_bowlers AS (
    /* 1.  Find every bowler who has at least one winning‑game
           (handicap ≤190) at EACH of the three required venues. */
    SELECT  bs.BowlerID
    FROM    Bowler_Scores   AS bs
    JOIN    Tourney_Matches AS tm ON tm.MatchID  = bs.MatchID
    JOIN    Tournaments     AS tt ON tt.TourneyID = tm.TourneyID
    WHERE   bs.WonGame = 1
      AND   bs.HandiCapScore <= 190
      AND   tt.TourneyLocation IN ('Thunderbird Lanes',
                                   'Totem Lanes',
                                   'Bolero Lanes')
    GROUP BY bs.BowlerID
    HAVING  COUNT(DISTINCT tt.TourneyLocation) = 3          -- all three venues
)

SELECT  bs.BowlerID,
        b.BowlerFirstName,
        b.BowlerLastName,
        bs.MatchID,
        bs.GameNumber,
        bs.HandiCapScore,
        tt.TourneyDate,
        tt.TourneyLocation
FROM        Bowler_Scores   AS bs
JOIN        qualified_bowlers qb ON qb.BowlerID = bs.BowlerID     -- only the bowlers who met the test
JOIN        Tourney_Matches  AS tm ON tm.MatchID  = bs.MatchID
JOIN        Tournaments      AS tt ON tt.TourneyID = tm.TourneyID
JOIN        Bowlers          AS b  ON b.BowlerID  = bs.BowlerID
WHERE       bs.WonGame = 1
  AND       bs.HandiCapScore <= 190
  AND       tt.TourneyLocation IN ('Thunderbird Lanes',
                                   'Totem Lanes',
                                   'Bolero Lanes')                -- only the three venues
ORDER BY    b.BowlerLastName,
            b.BowlerFirstName,
            tt.TourneyDate,
            bs.MatchID,
            bs.GameNumber;