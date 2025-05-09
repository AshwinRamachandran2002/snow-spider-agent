WITH over_totals AS (
    SELECT bs."match_id",
           bs."innings_no",
           bs."over_id",
           SUM(bs."runs_scored") + COALESCE(SUM(er."extra_runs"),0) AS total_runs
    FROM "batsman_scored" AS bs
    LEFT JOIN "extra_runs" AS er
         ON bs."match_id"   = er."match_id"
        AND bs."innings_no" = er."innings_no"
        AND bs."over_id"    = er."over_id"
    GROUP BY bs."match_id", bs."innings_no", bs."over_id"
),
best_over AS (
    SELECT match_id,
           innings_no,
           over_id,
           total_runs
    FROM (
        SELECT ot.*,
               ROW_NUMBER() OVER (PARTITION BY match_id
                                  ORDER BY total_runs DESC, innings_no, over_id) AS rn
        FROM over_totals ot
    )
    WHERE rn = 1
),
best_over_bowler AS (
    SELECT bo.match_id,
           bo.total_runs,
           MIN(bb.bowler) AS bowler          -- one bowler per over; MIN gives single value
    FROM best_over bo
    JOIN "ball_by_ball" bb
         ON  bo.match_id   = bb.match_id
         AND bo.innings_no = bb.innings_no
         AND bo.over_id    = bb.over_id
    GROUP BY bo.match_id, bo.total_runs
)
SELECT ROUND(AVG(total_runs), 4) AS average_highest_over_runs
FROM   best_over_bowler;