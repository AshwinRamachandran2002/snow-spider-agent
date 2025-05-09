WITH q AS (
    SELECT
        s."BowlerID",
        b."BowlerFirstName",
        b."BowlerLastName",
        s."MatchID",
        s."GameNumber",
        s."HandiCapScore",
        t."TourneyDate",
        t."TourneyLocation"
    FROM BOWLINGLEAGUE.BOWLINGLEAGUE."BOWLER_SCORES"        AS s
    JOIN BOWLINGLEAGUE.BOWLINGLEAGUE."TOURNEY_MATCHES"      AS tm
         ON s."MatchID" = tm."MatchID"
    JOIN BOWLINGLEAGUE.BOWLINGLEAGUE."TOURNAMENTS"          AS t
         ON tm."TourneyID" = t."TourneyID"
    JOIN BOWLINGLEAGUE.BOWLINGLEAGUE."BOWLERS"              AS b
         ON s."BowlerID" = b."BowlerID"
    WHERE s."WonGame" = 1
      AND s."HandiCapScore" <= 190
      AND t."TourneyLocation" IN ('Thunderbird Lanes', 'Totem Lanes', 'Bolero Lanes')
),
qualified_bowlers AS (
    SELECT "BowlerID"
    FROM q
    GROUP BY "BowlerID"
    HAVING COUNT(DISTINCT "TourneyLocation") = 3   -- must have a win at all three venues
)
SELECT
    q."BowlerID",
    q."BowlerFirstName",
    q."BowlerLastName",
    q."MatchID",
    q."GameNumber",
    q."HandiCapScore",
    q."TourneyDate",
    q."TourneyLocation"
FROM q
JOIN qualified_bowlers qb
  ON q."BowlerID" = qb."BowlerID"
ORDER BY
    q."BowlerLastName",
    q."BowlerFirstName",
    q."TourneyDate",
    q."MatchID",
    q."GameNumber";