WITH per_ball AS (
    SELECT  b.match_id,
            b.innings_no,
            b.over_id,
            b.bowler,
            COALESCE(bs.runs_scored,0) + COALESCE(er.extra_runs,0) AS runs_in_ball
    FROM    ball_by_ball b
    LEFT JOIN batsman_scored bs
           ON bs.match_id  = b.match_id
          AND bs.over_id   = b.over_id
          AND bs.ball_id   = b.ball_id
          AND bs.innings_no= b.innings_no
    LEFT JOIN extra_runs  er
           ON er.match_id  = b.match_id
          AND er.over_id   = b.over_id
          AND er.ball_id   = b.ball_id
          AND er.innings_no= b.innings_no
),
per_over AS (
    SELECT  match_id,
            innings_no,
            over_id,
            bowler,
            SUM(runs_in_ball) AS runs_in_over
    FROM    per_ball
    GROUP BY match_id, innings_no, over_id, bowler
),
max_over_per_match AS (
    SELECT  po.*,
            MAX(runs_in_over) OVER (PARTITION BY match_id) AS max_runs_in_match
    FROM    per_over po
),
overs_that_are_match_max AS (
    SELECT  match_id,
            bowler,
            runs_in_over
    FROM    max_over_per_match
    WHERE   runs_in_over = max_runs_in_match
),
best_over_per_bowler AS (
    SELECT  bowler,
            match_id,
            runs_in_over,
            ROW_NUMBER() OVER (PARTITION BY bowler ORDER BY runs_in_over DESC, match_id) AS rn
    FROM    overs_that_are_match_max
),
top_3 AS (
    SELECT  bowler,
            match_id,
            runs_in_over
    FROM    best_over_per_bowler
    WHERE   rn = 1
    ORDER BY runs_in_over DESC, bowler
    LIMIT   3
)
SELECT      p.player_name   AS bowler_name,
            t.match_id,
            t.runs_in_over  AS runs_conceded_in_over
FROM        top_3 t
JOIN        player p
          ON p.player_id = t.bowler
ORDER BY    t.runs_in_over DESC, bowler_name;