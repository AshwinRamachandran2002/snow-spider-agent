WITH QualifyingBowlers AS (
    SELECT  bs."BowlerID"
    FROM    Bowler_Scores          AS bs
    JOIN    Tourney_Matches        AS tm ON bs."MatchID" = tm."MatchID"
    JOIN    Tournaments            AS t  ON tm."TourneyID" = t."TourneyID"
    WHERE   bs."WonGame" = 1
      AND   bs."HandiCapScore" <= 190
      AND   t."TourneyLocation" IN ('Thunderbird Lanes',
                                    'Totem Lanes',
                                    'Bolero Lanes')
    GROUP BY bs."BowlerID"
    HAVING  COUNT(DISTINCT t."TourneyLocation") = 3      -- must have a win (≤190) at all three venues
)

SELECT  b."BowlerID",
        b."BowlerFirstName",
        b."BowlerLastName",
        bs."MatchID"        AS "MatchNumber",
        bs."GameNumber",
        bs."HandiCapScore",
        t."TourneyDate",
        t."TourneyLocation"
FROM        Bowler_Scores      AS bs
JOIN        QualifyingBowlers  AS q  ON bs."BowlerID" = q."BowlerID"
JOIN        Bowlers            AS b  ON b."BowlerID"  = bs."BowlerID"
JOIN        Tourney_Matches    AS tm ON bs."MatchID"  = tm."MatchID"
JOIN        Tournaments        AS t  ON tm."TourneyID" = t."TourneyID"
WHERE       bs."WonGame" = 1
  AND       bs."HandiCapScore" <= 190
  AND       t."TourneyLocation" IN ('Thunderbird Lanes',
                                    'Totem Lanes',
                                    'Bolero Lanes')
ORDER BY    b."BowlerLastName",
            b."BowlerFirstName",
            t."TourneyDate",
            bs."MatchID",
            bs."GameNumber";