WITH "BALL_RUNS" AS (   -- runs scored by every striker in every individual match
    SELECT
        BB."striker"      AS "player_id",
        BB."match_id",
        SUM(BS."runs_scored") AS "runs_in_match"
    FROM IPL.IPL."BALL_BY_BALL" BB
    JOIN IPL.IPL."BATSMAN_SCORED" BS
      ON  BB."match_id"   = BS."match_id"
      AND BB."innings_no" = BS."innings_no"
      AND BB."over_id"    = BS."over_id"
      AND BB."ball_id"    = BS."ball_id"
    GROUP BY
        BB."striker",
        BB."match_id"
),
"PLAYER_AVG" AS (       -- each player's average runs per match
    SELECT
        "player_id",
        ROUND(AVG("runs_in_match"), 4) AS "avg_runs_per_match"
    FROM "BALL_RUNS"
    GROUP BY
        "player_id"
),
"COUNTRY_AVG" AS (      -- country-wise average of those player averages
    SELECT
        P."country_name",
        ROUND(AVG(PA."avg_runs_per_match"), 4) AS "country_batting_average"
    FROM "PLAYER_AVG" PA
    JOIN IPL.IPL."PLAYER" P
      ON PA."player_id" = P."player_id"
    GROUP BY
        P."country_name"
)
SELECT
    "country_name",
    "country_batting_average"
FROM "COUNTRY_AVG"
ORDER BY
    "country_batting_average" DESC NULLS LAST
LIMIT 5;