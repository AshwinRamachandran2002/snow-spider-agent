WITH EligibleWins AS (
    SELECT bs."BowlerID",
           bs."MatchID",
           bs."GameNumber",
           bs."HandiCapScore",
           t."TourneyDate",
           t."TourneyLocation"
    FROM   "Bowler_Scores"   AS bs
    JOIN   "Tourney_Matches" AS tm ON tm."MatchID"  = bs."MatchID"
    JOIN   "Tournaments"     AS t  ON t."TourneyID" = tm."TourneyID"
    WHERE  bs."WonGame" = 1
      AND  bs."HandiCapScore" <= 190
      AND  t."TourneyLocation" IN ('Thunderbird Lanes',
                                   'Totem Lanes',
                                   'Bolero Lanes')
),
QualifiedBowlers AS (
    SELECT "BowlerID"
    FROM   EligibleWins
    GROUP BY "BowlerID"
    HAVING COUNT(DISTINCT "TourneyLocation") = 3   -- won (<=190) at all three venues
)
SELECT ew."BowlerID",
       b."BowlerFirstName",
       b."BowlerLastName",
       ew."MatchID",
       ew."GameNumber",
       ew."HandiCapScore",
       ew."TourneyDate",
       ew."TourneyLocation"
FROM   EligibleWins    AS ew
JOIN   QualifiedBowlers AS qb ON qb."BowlerID" = ew."BowlerID"
JOIN   "Bowlers"        AS b  ON b."BowlerID" = ew."BowlerID"
ORDER BY b."BowlerLastName",
         b."BowlerFirstName",
         ew."TourneyDate",
         ew."MatchID",
         ew."GameNumber";