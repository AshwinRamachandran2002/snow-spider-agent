-- Bowlers who have a ≤190-score win at ALL THREE venues
WITH venue_wins AS (        -- one row per bowler/venue with a qualifying win
    SELECT bs."BowlerID",
           t."TourneyLocation"
    FROM   "Bowler_Scores"  AS bs
    JOIN   "Tourney_Matches" AS tm ON tm."MatchID" = bs."MatchID"
    JOIN   "Tournaments"     AS t  ON t."TourneyID" = tm."TourneyID"
    WHERE  bs."WonGame"       = 1
      AND  bs."HandiCapScore" <= 190
      AND  t."TourneyLocation" IN ('Thunderbird Lanes',
                                   'Totem Lanes',
                                   'Bolero Lanes')
    GROUP BY bs."BowlerID", t."TourneyLocation"
), qualified_bowlers AS (   -- keep only bowlers who hit all three venues
    SELECT "BowlerID"
    FROM   venue_wins
    GROUP BY "BowlerID"
    HAVING COUNT(DISTINCT "TourneyLocation") = 3
)

SELECT b."BowlerID",
       b."BowlerFirstName",
       b."BowlerLastName",
       bs."MatchID",
       bs."GameNumber",
       bs."HandiCapScore",
       t."TourneyDate",
       t."TourneyLocation"
FROM   "Bowler_Scores"  AS bs
JOIN   "Tourney_Matches" AS tm ON tm."MatchID" = bs."MatchID"
JOIN   "Tournaments"     AS t  ON t."TourneyID" = tm."TourneyID"
JOIN   "Bowlers"         AS b  ON b."BowlerID" = bs."BowlerID"
WHERE  bs."WonGame"       = 1
  AND  bs."HandiCapScore" <= 190
  AND  t."TourneyLocation" IN ('Thunderbird Lanes',
                               'Totem Lanes',
                               'Bolero Lanes')
  AND  bs."BowlerID" IN (SELECT "BowlerID" FROM qualified_bowlers)
ORDER BY b."BowlerLastName",
         b."BowlerFirstName",
         t."TourneyDate",
         bs."GameNumber";