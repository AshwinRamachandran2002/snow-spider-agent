WITH ball_runs AS (
    -- Runs (batsman + extras) conceded by every bowler on every ball
    SELECT
        bb."bowler"                                            AS bowler_id,
        COALESCE(bs."runs_scored", 0) + COALESCE(er."extra_runs", 0) AS runs_conceded
    FROM IPL.IPL."BALL_BY_BALL" bb
    LEFT JOIN IPL.IPL."BATSMAN_SCORED" bs
           ON  bb."match_id"   = bs."match_id"
           AND bb."innings_no" = bs."innings_no"
           AND bb."over_id"    = bs."over_id"
           AND bb."ball_id"    = bs."ball_id"
    LEFT JOIN IPL.IPL."EXTRA_RUNS" er
           ON  bb."match_id"   = er."match_id"
           AND bb."innings_no" = er."innings_no"
           AND bb."over_id"    = er."over_id"
           AND bb."ball_id"    = er."ball_id"
),
runs_per_bowler AS (
    SELECT
        bowler_id AS player_id,
        SUM(runs_conceded) AS total_runs
    FROM ball_runs
    GROUP BY bowler_id
),
wickets_per_bowler AS (
    -- All wickets credited to the bowler (exclude run-outs & similar)
    SELECT
        bb."bowler" AS player_id,
        COUNT(*)    AS wickets
    FROM IPL.IPL."WICKET_TAKEN" wt
    JOIN IPL.IPL."BALL_BY_BALL" bb
         ON  wt."match_id"   = bb."match_id"
         AND wt."innings_no" = bb."innings_no"
         AND wt."over_id"    = bb."over_id"
         AND wt."ball_id"    = bb."ball_id"
    WHERE LOWER(wt."kind_out") NOT IN ('run out', 'retired hurt', 'obstructing the field')
    GROUP BY bb."bowler"
),
bowling_avg AS (
    -- Bowling average = runs conceded / wickets taken
    SELECT
        r.player_id,
        r.total_runs,
        w.wickets,
        r.total_runs / w.wickets AS bowling_average
    FROM runs_per_bowler r
    JOIN wickets_per_bowler w
      ON r.player_id = w.player_id
    WHERE w.wickets > 0
)
SELECT
    p."player_name",
    ROUND(b.bowling_average, 4) AS bowling_average
FROM bowling_avg b
JOIN IPL.IPL."PLAYER" p
  ON p."player_id" = b.player_id
ORDER BY bowling_average ASC NULLS LAST
LIMIT 1;