SELECT
        bs."BowlerID",
        b."BowlerFirstName",
        b."BowlerLastName",
        bs."MatchID",
        bs."GameNumber",
        bs."HandiCapScore",
        t."TourneyDate",
        t."TourneyLocation"
FROM    "Bowler_Scores"  AS bs
JOIN    "Bowlers"        AS b  ON b."BowlerID"   = bs."BowlerID"
JOIN    "Tourney_Matches" AS tm ON tm."MatchID"  = bs."MatchID"
JOIN    "Tournaments"     AS t  ON t."TourneyID" = tm."TourneyID"
WHERE   bs."WonGame" = 1
  AND   bs."HandiCapScore" <= 190
  AND   t."TourneyLocation" IN ('Thunderbird Lanes',
                                'Totem Lanes',
                                'Bolero Lanes')
  AND   bs."BowlerID" IN (
          SELECT  q."BowlerID"
          FROM   (
                  SELECT  bs2."BowlerID",
                          COUNT(DISTINCT t2."TourneyLocation") AS loc_cnt
                  FROM    "Bowler_Scores"  AS bs2
                  JOIN    "Tourney_Matches" AS tm2 ON tm2."MatchID"  = bs2."MatchID"
                  JOIN    "Tournaments"     AS t2  ON t2."TourneyID" = tm2."TourneyID"
                  WHERE   bs2."WonGame" = 1
                    AND   bs2."HandiCapScore" <= 190
                    AND   t2."TourneyLocation" IN ('Thunderbird Lanes',
                                                   'Totem Lanes',
                                                   'Bolero Lanes')
                  GROUP BY bs2."BowlerID"
                 ) AS q
          WHERE  q.loc_cnt = 3
        )
ORDER BY bs."BowlerID",
         t."TourneyDate",
         bs."GameNumber";