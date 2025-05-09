-- Bowlers who have won (≤190-handicap) games at ALL THREE venues,
-- and the details of each such winning game at those venues
SELECT  b."BowlerID",
        b."BowlerFirstName",
        b."BowlerLastName",
        bs."MatchID",
        bs."GameNumber",
        bs."HandiCapScore",
        t."TourneyDate",
        t."TourneyLocation"
FROM    "Bowler_Scores"  AS bs
JOIN    "Tourney_Matches" AS tm ON bs."MatchID" = tm."MatchID"
JOIN    "Tournaments"     AS t  ON tm."TourneyID" = t."TourneyID"
JOIN    "Bowlers"         AS b  ON bs."BowlerID" = b."BowlerID"
WHERE   bs."WonGame" = 1
  AND   bs."HandiCapScore" <= 190
  AND   t."TourneyLocation" IN ('Thunderbird Lanes',
                                'Totem Lanes',
                                'Bolero Lanes')
  AND   bs."BowlerID" IN (      -- keep only bowlers who succeeded at ALL 3 venues
        SELECT  bs2."BowlerID"
        FROM    "Bowler_Scores"  AS bs2
        JOIN    "Tourney_Matches" AS tm2 ON bs2."MatchID" = tm2."MatchID"
        JOIN    "Tournaments"     AS t2  ON tm2."TourneyID" = t2."TourneyID"
        WHERE   bs2."WonGame" = 1
          AND   bs2."HandiCapScore" <= 190
          AND   t2."TourneyLocation" IN ('Thunderbird Lanes',
                                         'Totem Lanes',
                                         'Bolero Lanes')
        GROUP BY bs2."BowlerID"
        HAVING  COUNT(DISTINCT t2."TourneyLocation") = 3
  )
ORDER BY b."BowlerLastName",
         b."BowlerFirstName",
         t."TourneyDate",
         bs."GameNumber";