WITH
    bat AS (
        SELECT match_id,
               over_id,
               ball_id,
               innings_no,
               runs_scored
        FROM batsman_scored
    ),
    ex AS (
        SELECT match_id,
               over_id,
               ball_id,
               innings_no,
               SUM(CASE WHEN extra_type IN ('wides','noballs')
                        THEN extra_runs ELSE 0 END) AS extra_runs
        FROM extra_runs
        GROUP BY match_id, over_id, ball_id, innings_no
    ),
    wk AS (
        SELECT match_id,
               over_id,
               ball_id,
               innings_no,
               MAX(CASE WHEN kind_out NOT IN ('run out','retired hurt','obstructing the field')
                        THEN 1 ELSE 0 END) AS is_wicket
        FROM wicket_taken
        GROUP BY match_id, over_id, ball_id, innings_no
    ),
    ball_data AS (
        SELECT
            bb.bowler,
            COALESCE(bat.runs_scored, 0) + COALESCE(ex.extra_runs, 0) AS runs_conceded,
            COALESCE(wk.is_wicket, 0)                                 AS bowler_wicket
        FROM ball_by_ball bb
        LEFT JOIN bat ON bat.match_id   = bb.match_id
                     AND bat.over_id    = bb.over_id
                     AND bat.ball_id    = bb.ball_id
                     AND bat.innings_no = bb.innings_no
        LEFT JOIN ex  ON ex.match_id    = bb.match_id
                     AND ex.over_id     = bb.over_id
                     AND ex.ball_id     = bb.ball_id
                     AND ex.innings_no  = bb.innings_no
        LEFT JOIN wk  ON wk.match_id    = bb.match_id
                     AND wk.over_id     = bb.over_id
                     AND wk.ball_id     = bb.ball_id
                     AND wk.innings_no  = bb.innings_no
    ),
    agg AS (
        SELECT
            bowler,
            SUM(runs_conceded) AS total_runs,
            SUM(bowler_wicket) AS wickets
        FROM ball_data
        GROUP BY bowler
        HAVING wickets > 0
    )
SELECT
    p.player_name                                 AS bowler,
    ROUND(1.0 * total_runs / wickets, 4)          AS bowling_average
FROM agg
JOIN player p ON p.player_id = agg.bowler
ORDER BY bowling_average ASC, bowler
LIMIT 1;