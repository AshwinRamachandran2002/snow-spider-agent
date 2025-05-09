SELECT
    b."BowlerID",
    b."BowlerFirstName",
    b."BowlerLastName",
    bs."MatchID",
    bs."GameNumber",
    bs."HandiCapScore",
    t."TourneyDate",
    t."TourneyLocation"
FROM "Bowlers"        AS b
JOIN "Bowler_Scores"  AS bs ON bs."BowlerID"   = b."BowlerID"
JOIN "Tourney_Matches" AS tm ON tm."MatchID"   = bs."MatchID"
JOIN "Tournaments"     AS t  ON t."TourneyID"  = tm."TourneyID"
WHERE
      bs."WonGame" = 1
  AND bs."HandiCapScore" <= 190
  AND t."TourneyLocation" IN ('Thunderbird Lanes', 'Totem Lanes', 'Bolero Lanes')
  AND b."BowlerID" IN (         -- bowlers who achieved such a win at all three venues
        SELECT bs2."BowlerID"
        FROM "Bowler_Scores"  AS bs2
        JOIN "Tourney_Matches" AS tm2 ON tm2."MatchID"  = bs2."MatchID"
        JOIN "Tournaments"     AS t2  ON t2."TourneyID" = tm2."TourneyID"
        WHERE
              bs2."WonGame" = 1
          AND bs2."HandiCapScore" <= 190
          AND t2."TourneyLocation" IN ('Thunderbird Lanes', 'Totem Lanes', 'Bolero Lanes')
        GROUP BY bs2."BowlerID"
        HAVING COUNT(DISTINCT t2."TourneyLocation") = 3
  )
ORDER BY
    b."BowlerLastName",
    b."BowlerFirstName",
    t."TourneyDate",
    bs."GameNumber";