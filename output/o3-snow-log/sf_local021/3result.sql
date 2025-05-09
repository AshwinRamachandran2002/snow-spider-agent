WITH player_match_runs AS (
    /* runs scored by every striker in each match */
    SELECT
        b."match_id",
        bb."striker"                                         AS "player_id",
        SUM(b."runs_scored")                                 AS "total_runs"
    FROM IPL.IPL.BATSMAN_SCORED          b
    JOIN IPL.IPL.BALL_BY_BALL            bb
      ON  b."match_id"   = bb."match_id"
      AND b."innings_no" = bb."innings_no"
      AND b."over_id"    = bb."over_id"
      AND b."ball_id"    = bb."ball_id"
    GROUP BY
        b."match_id",
        bb."striker"
),
qualified_scores AS (
    /* keep only (player, match) totals exceeding 50 runs */
    SELECT
        "total_runs"
    FROM player_match_runs
    WHERE "total_runs" > 50
)
SELECT
    ROUND(AVG("total_runs"), 4)  AS "average_runs"
FROM qualified_scores;