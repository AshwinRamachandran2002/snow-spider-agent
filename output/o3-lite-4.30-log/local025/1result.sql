WITH ball_runs AS (
    SELECT  bb.match_id,
            bb.innings_no,
            bb.over_id,
            COALESCE(bs.runs_scored,0) + COALESCE(er.extra_runs,0) AS total_runs
    FROM   ball_by_ball AS bb
    LEFT JOIN batsman_scored AS bs
           ON bs.match_id   = bb.match_id
          AND bs.innings_no = bb.innings_no
          AND bs.over_id    = bb.over_id
          AND bs.ball_id    = bb.ball_id
    LEFT JOIN extra_runs   AS er
           ON er.match_id   = bb.match_id
          AND er.innings_no = bb.innings_no
          AND er.over_id    = bb.over_id
          AND er.ball_id    = bb.ball_id
),
over_totals AS (
    SELECT match_id,
           innings_no,
           over_id,
           SUM(total_runs) AS over_total
    FROM   ball_runs
    GROUP BY match_id, innings_no, over_id
),
ranked_overs AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY match_id
                              ORDER BY over_total DESC,
                                       innings_no,
                                       over_id) AS rn
    FROM   over_totals
),
best_over AS (
    SELECT match_id,
           innings_no,
           over_id,
           over_total
    FROM   ranked_overs
    WHERE  rn = 1
),
best_over_bowler AS (
    SELECT bo.match_id,
           bo.over_total,
           MIN(bb.bowler) AS bowler_id        -- over has single bowler; MIN picks that bowler
    FROM   best_over      AS bo
    JOIN   ball_by_ball   AS bb
           ON bb.match_id   = bo.match_id
          AND bb.innings_no = bo.innings_no
          AND bb.over_id    = bo.over_id
    GROUP BY bo.match_id, bo.over_total
)
SELECT ROUND(AVG(over_total),4) AS average_highest_over_runs
FROM   best_over_bowler;