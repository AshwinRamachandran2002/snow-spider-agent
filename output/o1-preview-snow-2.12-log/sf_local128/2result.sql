SELECT
  b."BowlerFirstName" || ' ' || b."BowlerLastName" AS "BowlerName",
  bs."MatchID" AS "MatchNumber",
  bs."GameNumber",
  TO_CHAR(bs."HandiCapScore", 'FM999999990.0000') AS "HandicapScore",
  t."TourneyDate" AS "TournamentDate",
  t."TourneyLocation" AS "Location"
FROM BOWLINGLEAGUE.BOWLINGLEAGUE.BOWLER_SCORES bs
JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.BOWLERS b ON bs."BowlerID" = b."BowlerID"
JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.TOURNEY_MATCHES tm ON bs."MatchID" = tm."MatchID"
JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.TOURNAMENTS t ON tm."TourneyID" = t."TourneyID"
WHERE bs."WonGame" = 1
  AND bs."HandiCapScore" <= 190
  AND t."TourneyLocation" IN ('Thunderbird Lanes', 'Totem Lanes', 'Bolero Lanes');