WITH qualified_games AS (
    SELECT
        bs."BowlerID",
        bs."MatchID",
        bs."GameNumber",
        bs."HandiCapScore",
        t."TourneyDate",
        t."TourneyLocation"
    FROM BOWLINGLEAGUE.BOWLINGLEAGUE.BOWLER_SCORES            bs
    JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.TOURNEY_MATCHES           tm
         ON bs."MatchID" = tm."MatchID"
    JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.TOURNAMENTS               t
         ON tm."TourneyID" = t."TourneyID"
    WHERE bs."WonGame" = 1
      AND bs."HandiCapScore" <= 190
      AND t."TourneyLocation" IN ('Thunderbird Lanes', 'Totem Lanes', 'Bolero Lanes')
),
bowlers_with_all_three AS (
    SELECT
        "BowlerID"
    FROM qualified_games
    GROUP BY "BowlerID"
    HAVING COUNT(DISTINCT "TourneyLocation") = 3
)
SELECT
    b."BowlerID",
    b."BowlerFirstName",
    b."BowlerLastName",
    q."MatchID",
    q."GameNumber",
    q."HandiCapScore",
    q."TourneyDate",
    q."TourneyLocation"
FROM qualified_games               q
JOIN bowlers_with_all_three        bw
     ON q."BowlerID" = bw."BowlerID"
JOIN BOWLINGLEAGUE.BOWLINGLEAGUE.BOWLERS b
     ON q."BowlerID" = b."BowlerID"
ORDER BY
    b."BowlerLastName",
    b."BowlerFirstName",
    q."TourneyDate",
    q."MatchID",
    q."GameNumber";