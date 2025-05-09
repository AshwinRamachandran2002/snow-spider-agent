SELECT
  b."BowlerFirstName" || ' ' || b."BowlerLastName" AS "BowlerName",
  bs."MatchID" AS "MatchNumber",
  bs."GameNumber",
  bs."HandiCapScore",
  t."TourneyDate" AS "TournamentDate",
  t."TourneyLocation" AS "Location"
FROM "Bowler_Scores" bs
JOIN "Bowlers" b ON bs."BowlerID" = b."BowlerID"
JOIN "Tourney_Matches" tm ON bs."MatchID" = tm."MatchID"
JOIN "Tournaments" t ON tm."TourneyID" = t."TourneyID"
WHERE
  bs."WonGame" = 1
  AND bs."HandiCapScore" <= 190
  AND t."TourneyLocation" IN ('Thunderbird Lanes', 'Totem Lanes', 'Bolero Lanes')
ORDER BY
  bs."HandiCapScore" ASC;