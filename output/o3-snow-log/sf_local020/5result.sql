WITH ball_details AS (
    -- runs (off the bat + all extras) conceded on every delivery bowled
    SELECT
        b."bowler",
        COALESCE(bs."runs_scored",0) + COALESCE(er."extra_runs",0) AS runs_conceded
    FROM IPL.IPL."BALL_BY_BALL"      b
    LEFT JOIN IPL.IPL."BATSMAN_SCORED" bs
           ON  b."match_id"  = bs."match_id"
           AND b."innings_no"= bs."innings_no"
           AND b."over_id"   = bs."over_id"
           AND b."ball_id"   = bs."ball_id"
    LEFT JOIN IPL.IPL."EXTRA_RUNS"    er
           ON  b."match_id"  = er."match_id"
           AND b."innings_no"= er."innings_no"
           AND b."over_id"   = er."over_id"
           AND b."ball_id"   = er."ball_id"
),
bowler_runs AS (
    SELECT
        "bowler"                    AS bowler_id,
        SUM(runs_conceded)          AS total_runs
    FROM ball_details
    GROUP BY "bowler"
),
wickets AS (
    -- wickets credited to bowler (exclude run-outs)
    SELECT
        b."bowler"                  AS bowler_id,
        COUNT(*)                    AS wickets
    FROM IPL.IPL."WICKET_TAKEN" w
    JOIN IPL.IPL."BALL_BY_BALL"  b
         ON  b."match_id"   = w."match_id"
         AND b."innings_no" = w."innings_no"
         AND b."over_id"    = w."over_id"
         AND b."ball_id"    = w."ball_id"
    WHERE LOWER(w."kind_out") <> 'run out'
    GROUP BY b."bowler"
),
bowler_stats AS (
    SELECT
        r.bowler_id,
        r.total_runs,
        w.wickets,
        r.total_runs / w.wickets     AS bowling_average
    FROM bowler_runs r
    JOIN wickets     w
      ON r.bowler_id = w.bowler_id
    WHERE w.wickets > 0
)
SELECT
    p."player_name"                 AS bowler_name,
    bs.bowling_average
FROM bowler_stats bs
JOIN IPL.IPL."PLAYER" p
  ON bs.bowler_id = p."player_id"
ORDER BY bs.bowling_average ASC NULLS LAST
LIMIT 1;