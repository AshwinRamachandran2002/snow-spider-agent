SELECT
    b."BowlerID"            AS bowler_id,
    b."BowlerFirstName"     AS first_name,
    b."BowlerLastName"      AS last_name,
    bs."MatchID"            AS match_number,
    bs."GameNumber"         AS game_number,
    bs."HandiCapScore"      AS handicap_score,
    t."TourneyDate"         AS tournament_date,
    t."TourneyLocation"     AS location
FROM   "Bowler_Scores"   AS bs
JOIN   "Bowlers"         AS b  ON b."BowlerID"   = bs."BowlerID"
JOIN   "Tourney_Matches" AS tm ON tm."MatchID"   = bs."MatchID"
JOIN   "Tournaments"     AS t  ON t."TourneyID"  = tm."TourneyID"
WHERE  bs."WonGame" = 1
  AND  bs."HandiCapScore" <= 190
  AND  t."TourneyLocation" IN ('Thunderbird Lanes', 'Totem Lanes', 'Bolero Lanes')
  AND  bs."BowlerID" IN (
        SELECT bs2."BowlerID"
        FROM   "Bowler_Scores"   AS bs2
        JOIN   "Tourney_Matches" AS tm2 ON tm2."MatchID"  = bs2."MatchID"
        JOIN   "Tournaments"     AS t2  ON t2."TourneyID" = tm2."TourneyID"
        WHERE  bs2."WonGame" = 1
          AND  bs2."HandiCapScore" <= 190
          AND  t2."TourneyLocation" IN ('Thunderbird Lanes', 'Totem Lanes', 'Bolero Lanes')
        GROUP  BY bs2."BowlerID"
        HAVING COUNT(DISTINCT t2."TourneyLocation") = 3
      )
ORDER BY
    b."BowlerLastName",
    b."BowlerFirstName",
    t."TourneyDate",
    bs."GameNumber";