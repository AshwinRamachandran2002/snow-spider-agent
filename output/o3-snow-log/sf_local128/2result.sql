WITH candidate AS (
    SELECT 
        bs."BowlerID",
        b."BowlerFirstName",
        b."BowlerLastName",
        bs."MatchID",
        bs."GameNumber",
        bs."HandiCapScore",
        t."TourneyDate",
        t."TourneyLocation"
    FROM "BOWLINGLEAGUE"."BOWLINGLEAGUE"."BOWLER_SCORES"         bs
    JOIN "BOWLINGLEAGUE"."BOWLINGLEAGUE"."TOURNEY_MATCHES"       tm
          ON bs."MatchID" = tm."MatchID"
    JOIN "BOWLINGLEAGUE"."BOWLINGLEAGUE"."TOURNAMENTS"           t
          ON tm."TourneyID" = t."TourneyID"
    JOIN "BOWLINGLEAGUE"."BOWLINGLEAGUE"."BOWLERS"               b
          ON bs."BowlerID" = b."BowlerID"
    WHERE bs."WonGame" = 1
      AND bs."HandiCapScore" <= 190
      AND t."TourneyLocation" IN ('Thunderbird Lanes',
                                  'Totem Lanes',
                                  'Bolero Lanes')
),
qualified AS (
    SELECT "BowlerID"
    FROM candidate
    GROUP BY "BowlerID"
    HAVING COUNT(DISTINCT "TourneyLocation") = 3          -- must have wins at all 3 venues
)

SELECT 
    c."BowlerID",
    c."BowlerFirstName",
    c."BowlerLastName",
    c."MatchID",
    c."GameNumber",
    c."HandiCapScore",
    c."TourneyDate",
    c."TourneyLocation"
FROM candidate c
JOIN qualified q
  ON c."BowlerID" = q."BowlerID"
ORDER BY 
    c."BowlerID",
    c."TourneyDate",
    c."MatchID",
    c."GameNumber";