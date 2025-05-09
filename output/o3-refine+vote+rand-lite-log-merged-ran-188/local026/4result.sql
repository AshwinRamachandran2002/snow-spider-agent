WITH runs_per_ball AS (
    SELECT  b.match_id,
            b.innings_no,
            b.over_id,
            b.bowler,
            COALESCE(bs.runs_scored,0) + COALESCE(er.extra_runs,0) AS runs
    FROM   ball_by_ball AS b
    LEFT JOIN batsman_scored AS bs
           ON bs.match_id = b.match_id
          AND bs.innings_no = b.innings_no
          AND bs.over_id = b.over_id
          AND bs.ball_id = b.ball_id
    LEFT JOIN extra_runs   AS er
           ON er.match_id = b.match_id
          AND er.innings_no = b.innings_no
          AND er.over_id = b.over_id
          AND er.ball_id = b.ball_id
),

runs_per_over AS (
    SELECT  match_id,
            innings_no,
            over_id,
            bowler,
            SUM(runs) AS runs_in_over
    FROM    runs_per_ball
    GROUP BY match_id, innings_no, over_id, bowler
),

match_max_over AS (
    SELECT  rpo.*,
            (SELECT MAX(runs_in_over)
               FROM runs_per_over r2
              WHERE r2.match_id = rpo.match_id) AS max_runs_in_match
    FROM    runs_per_over AS rpo
),

only_max_overs AS (
    SELECT  match_id,
            innings_no,
            over_id,
            bowler,
            runs_in_over
    FROM    match_max_over
    WHERE   runs_in_over = max_runs_in_match
),

ranked_bowlers AS (
    SELECT  o.bowler,
            o.match_id,
            o.runs_in_over,
            p.player_name,
            DENSE_RANK() OVER (ORDER BY o.runs_in_over DESC) AS rk
    FROM    only_max_overs AS o
    JOIN    player        AS p
           ON p.player_id = o.bowler
)

SELECT  player_name  AS bowler_name,
        match_id,
        runs_in_over AS max_runs_in_single_over
FROM    ranked_bowlers
WHERE   rk <= 3
ORDER BY runs_in_over DESC,
         bowler_name
LIMIT 3;