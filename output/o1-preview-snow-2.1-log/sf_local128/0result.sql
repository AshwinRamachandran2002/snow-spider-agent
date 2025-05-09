SELECT CONCAT(b."BowlerFirstName", ' ', b."BowlerLastName") AS "BowlerName",
       bs."MatchID" AS "MatchNumber",
       bs."GameNumber",
       bs."HandiCapScore" AS "HandicapScore",
       t."TourneyDate" AS "TournamentDate",
       t."TourneyLocation" AS "Location"
FROM "BOWLINGLEAGUE"."BOWLINGLEAGUE"."BOWLERS" b
JOIN "BOWLINGLEAGUE"."BOWLINGLEAGUE"."BOWLER_SCORES" bs
  ON b."BowlerID" = bs."BowlerID"
JOIN "BOWLINGLEAGUE"."BOWLINGLEAGUE"."TOURNEY_MATCHES" tm
  ON bs."MatchID" = tm."MatchID"
JOIN "BOWLINGLEAGUE"."BOWLINGLEAGUE"."TOURNAMENTS" t
  ON tm."TourneyID" = t."TourneyID"
WHERE bs."HandiCapScore" <= 190
  AND bs."WonGame" = 1
  AND t."TourneyLocation" IN ('Thunderbird Lanes', 'Totem Lanes', 'Bolero Lanes');