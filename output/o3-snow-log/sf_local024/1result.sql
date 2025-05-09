WITH
/* every (player, match) combination in which the player appeared */
"player_matches" AS (
    SELECT DISTINCT
        "player_id",
        "match_id"
    FROM IPL.IPL."PLAYER_MATCH"
),

/* runs scored on every delivery, with the striker (batsman) identified */
"runs_per_delivery" AS (
    SELECT
        bb."striker"       AS "player_id",
        bb."match_id",
        bs."runs_scored"
    FROM IPL.IPL."BATSMAN_SCORED" bs
    JOIN IPL.IPL."BALL_BY_BALL"   bb
      ON bs."match_id"   = bb."match_id"
     AND bs."over_id"    = bb."over_id"
     AND bs."ball_id"    = bb."ball_id"
     AND bs."innings_no" = bb."innings_no"
),

/* total runs a player scored in a given match */
"runs_per_match" AS (
    SELECT
        "player_id",
        "match_id",
        SUM("runs_scored") AS "runs_in_match"
    FROM "runs_per_delivery"
    GROUP BY
        "player_id",
        "match_id"
),

/* attach a zero for matches where the player batted but scored no runs */
"player_match_runs" AS (
    SELECT
        pm."player_id",
        pm."match_id",
        COALESCE(rpm."runs_in_match", 0) AS "runs_in_match"
    FROM "player_matches" pm
    LEFT JOIN "runs_per_match" rpm
           ON pm."player_id" = rpm."player_id"
          AND pm."match_id"  = rpm."match_id"
),

/* per-player average runs per match */
"player_avg" AS (
    SELECT
        "player_id",
        SUM("runs_in_match")::FLOAT / COUNT(*) AS "avg_runs_per_match"
    FROM "player_match_runs"
    GROUP BY "player_id"
),

/* country-level average of these player averages */
"country_avg" AS (
    SELECT
        pl."country_name",
        AVG(pa."avg_runs_per_match") AS "country_batting_avg"
    FROM "player_avg"  pa
    JOIN IPL.IPL."PLAYER" pl
      ON pa."player_id" = pl."player_id"
    GROUP BY
        pl."country_name"
)

SELECT
    "country_name",
    ROUND("country_batting_avg", 4) AS "country_batting_avg"
FROM "country_avg"
ORDER BY
    "country_batting_avg" DESC NULLS LAST
LIMIT 5;