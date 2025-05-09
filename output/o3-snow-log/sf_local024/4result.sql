WITH "BALL_RUNS" AS (
    /* Runs scored by every striker on each ball */
    SELECT
        BB."match_id",
        BB."striker"                  AS "player_id",
        BS."runs_scored"
    FROM IPL.IPL."BALL_BY_BALL" BB
    JOIN IPL.IPL."BATSMAN_SCORED" BS
          ON  BB."match_id"  = BS."match_id"
          AND BB."over_id"   = BS."over_id"
          AND BB."ball_id"   = BS."ball_id"
          AND BB."innings_no"= BS."innings_no"
),
"PLAYER_MATCH_RUNS" AS (
    /* Total runs a player scores in every match he plays */
    SELECT
        "player_id",
        "match_id",
        SUM("runs_scored") AS "runs_in_match"
    FROM "BALL_RUNS"
    GROUP BY "player_id", "match_id"
),
"PLAYER_AVG" AS (
    /* Each player’s average runs per match across all matches */
    SELECT
        "player_id",
        AVG("runs_in_match") AS "avg_runs_per_match"
    FROM "PLAYER_MATCH_RUNS"
    GROUP BY "player_id"
),
"PLAYER_COUNTRY" AS (
    SELECT
        P."player_id",
        P."country_name"
    FROM IPL.IPL."PLAYER" P
),
"COUNTRY_AVG" AS (
    /* Country-level average of the players’ batting averages */
    SELECT
        PC."country_name",
        AVG(PA."avg_runs_per_match") AS "country_batting_avg"
    FROM "PLAYER_AVG"     PA
    JOIN "PLAYER_COUNTRY" PC
      ON PA."player_id" = PC."player_id"
    GROUP BY PC."country_name"
)
SELECT
    "country_name",
    ROUND("country_batting_avg", 4) AS "country_batting_average"
FROM "COUNTRY_AVG"
ORDER BY "country_batting_avg" DESC NULLS LAST
LIMIT 5;