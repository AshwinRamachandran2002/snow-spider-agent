WITH QUALIFIED_WINS AS (
    SELECT
        bs."BowlerID",
        bs."MatchID",
        bs."GameNumber",
        bs."HandiCapScore",
        t."TourneyDate",
        t."TourneyLocation"
    FROM BOWLINGLEAGUE.BOWLINGLEAGUE.BOWLER_SCORES      bs
    JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.TOURNEY_MATCHES    tm
         ON bs."MatchID" = tm."MatchID"
    JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.TOURNAMENTS        t
         ON tm."TourneyID" = t."TourneyID"
    WHERE bs."WonGame" = 1
      AND bs."HandiCapScore" <= 190
      AND t."TourneyLocation" IN ('Thunderbird Lanes', 'Totem Lanes', 'Bolero Lanes')
),
BOWLERS_ALL_VENUES AS (
    SELECT
        "BowlerID"
    FROM QUALIFIED_WINS
    GROUP BY "BowlerID"
    HAVING COUNT(DISTINCT "TourneyLocation") = 3        -- must have wins at all three venues
)
SELECT
    b."BowlerID",
    b."BowlerFirstName",
    b."BowlerLastName",
    q."MatchID"        AS "MatchNumber",
    q."GameNumber",
    q."HandiCapScore",
    q."TourneyDate",
    q."TourneyLocation"
FROM QUALIFIED_WINS          q
JOIN BOWLERS_ALL_VENUES      v  ON q."BowlerID" = v."BowlerID"
JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.BOWLERS b ON q."BowlerID" = b."BowlerID"
ORDER BY
    b."BowlerLastName",
    b."BowlerFirstName",
    q."TourneyDate",
    q."MatchID",
    q."GameNumber";