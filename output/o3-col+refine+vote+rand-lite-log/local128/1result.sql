WITH winners AS (
    SELECT bs."BowlerID"
    FROM   "Bowler_Scores"   AS bs
    JOIN   "Tourney_Matches" AS tm ON bs."MatchID"   = tm."MatchID"
    JOIN   "Tournaments"     AS t  ON tm."TourneyID" = t."TourneyID"
    WHERE  bs."WonGame"       = 1
      AND  bs."HandiCapScore" <= 190
      AND  t."TourneyLocation" IN ('Thunderbird Lanes',
                                   'Totem Lanes',
                                   'Bolero Lanes')
    GROUP  BY bs."BowlerID"
    HAVING COUNT(DISTINCT t."TourneyLocation") = 3
)

SELECT   b."BowlerID",
         b."BowlerFirstName",
         b."BowlerLastName",
         bs."MatchID",
         bs."GameNumber",
         bs."HandiCapScore",
         t."TourneyDate",
         t."TourneyLocation"
FROM     "Bowler_Scores"   AS bs
JOIN     winners           AS w  ON bs."BowlerID"  = w."BowlerID"
JOIN     "Tourney_Matches" AS tm ON bs."MatchID"   = tm."MatchID"
JOIN     "Tournaments"     AS t  ON tm."TourneyID" = t."TourneyID"
JOIN     "Bowlers"         AS b  ON bs."BowlerID"  = b."BowlerID"
WHERE    bs."WonGame"       = 1
  AND    bs."HandiCapScore" <= 190
  AND    t."TourneyLocation" IN ('Thunderbird Lanes',
                                 'Totem Lanes',
                                 'Bolero Lanes')
ORDER BY b."BowlerLastName",
         b."BowlerFirstName",
         t."TourneyDate",
         bs."GameNumber";