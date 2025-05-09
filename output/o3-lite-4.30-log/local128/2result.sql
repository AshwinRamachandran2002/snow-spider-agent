WITH qualifying_bowlers AS (
    SELECT bs."BowlerID"
    FROM   "Bowler_Scores"   AS bs
    JOIN   "Tourney_Matches" AS tm ON tm."MatchID" = bs."MatchID"
    JOIN   "Tournaments"     AS t  ON t."TourneyID" = tm."TourneyID"
    WHERE  bs."WonGame" = 1
      AND  bs."HandiCapScore" <= 190
      AND  t."TourneyLocation" IN ('Thunderbird Lanes','Totem Lanes','Bolero Lanes')
    GROUP  BY bs."BowlerID"
    HAVING COUNT(DISTINCT t."TourneyLocation") = 3
)

SELECT b."BowlerID"        AS bowler_id,
       b."BowlerFirstName" AS first_name,
       b."BowlerLastName"  AS last_name,
       bs."MatchID"        AS match_number,
       bs."GameNumber"     AS game_number,
       bs."HandiCapScore"  AS handicap_score,
       t."TourneyDate"     AS tournament_date,
       t."TourneyLocation" AS location
FROM   "Bowler_Scores"   AS bs
JOIN   "Bowlers"         AS b  ON b."BowlerID" = bs."BowlerID"
JOIN   "Tourney_Matches" AS tm ON tm."MatchID" = bs."MatchID"
JOIN   "Tournaments"     AS t  ON t."TourneyID" = tm."TourneyID"
WHERE  bs."WonGame" = 1
  AND  bs."HandiCapScore" <= 190
  AND  t."TourneyLocation" IN ('Thunderbird Lanes','Totem Lanes','Bolero Lanes')
  AND  bs."BowlerID" IN (SELECT "BowlerID" FROM qualifying_bowlers)
ORDER  BY b."BowlerID", t."TourneyDate", bs."GameNumber";