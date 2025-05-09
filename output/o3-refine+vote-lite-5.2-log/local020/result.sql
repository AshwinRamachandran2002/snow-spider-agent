WITH runs_per_ball AS (
    SELECT
        b.bowler                     AS bowler_id,
        COALESCE(bs.runs_scored,0) +
        COALESCE(er.extra_runs,0)    AS runs_conceded,
        CASE                       -- 1 if a wicket fell on this ball, else 0
            WHEN wt.match_id IS NULL THEN 0
            ELSE 1
        END                         AS wicket_taken
    FROM ball_by_ball b
    LEFT JOIN batsman_scored bs
           ON bs.match_id  = b.match_id
          AND bs.over_id   = b.over_id
          AND bs.ball_id   = b.ball_id
          AND bs.innings_no= b.innings_no
    LEFT JOIN extra_runs er
           ON er.match_id  = b.match_id
          AND er.over_id   = b.over_id
          AND er.ball_id   = b.ball_id
          AND er.innings_no= b.innings_no
    LEFT JOIN (
        SELECT DISTINCT
               match_id, over_id, ball_id, innings_no
        FROM   wicket_taken
    ) wt
           ON wt.match_id  = b.match_id
          AND wt.over_id   = b.over_id
          AND wt.ball_id   = b.ball_id
          AND wt.innings_no= b.innings_no
),
bowler_totals AS (
    SELECT
        bowler_id,
        SUM(runs_conceded)          AS total_runs_conceded,
        SUM(wicket_taken)           AS total_wickets
    FROM   runs_per_ball
    GROUP  BY bowler_id
    HAVING total_wickets > 0        -- avoid divide‑by‑zero
),
bowler_avg AS (
    SELECT
        bowler_id,
        1.0 * total_runs_conceded / total_wickets  AS bowling_average
    FROM   bowler_totals
)
SELECT
    p.player_name
FROM   bowler_avg  ba
JOIN   player       p  ON p.player_id = ba.bowler_id
ORDER  BY ba.bowling_average ASC
LIMIT  1;