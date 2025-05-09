WITH qualifying_games AS (
    SELECT bs."BowlerID",
           bs."MatchID",
           bs."GameNumber",
           bs."HandiCapScore",
           t."TourneyDate",
           t."TourneyLocation"
    FROM   "Bowler_Scores"   AS bs
    JOIN   "Tourney_Matches" AS tm ON tm."MatchID" = bs."MatchID"
    JOIN   "Tournaments"     AS t  ON t."TourneyID" = tm."TourneyID"
    WHERE  bs."WonGame" = 1
      AND  bs."HandiCapScore" <= 190
      AND  t."TourneyLocation" IN ('Thunderbird Lanes',
                                   'Totem Lanes',
                                   'Bolero Lanes')
),
eligible_bowlers AS (
    SELECT "BowlerID"
    FROM   qualifying_games
    GROUP BY "BowlerID"
    HAVING COUNT(DISTINCT "TourneyLocation") = 3
)
SELECT   b."BowlerID",
         b."BowlerFirstName",
         b."BowlerLastName",
         q."MatchID"        AS "MatchNumber",
         q."GameNumber",
         q."HandiCapScore",
         q."TourneyDate",
         q."TourneyLocation"
FROM     qualifying_games  AS q
JOIN     eligible_bowlers  AS e ON e."BowlerID" = q."BowlerID"
JOIN     "Bowlers"         AS b ON b."BowlerID" = q."BowlerID"
ORDER BY b."BowlerLastName",
         b."BowlerFirstName",
         q."TourneyDate",
         q."MatchID",
         q."GameNumber";