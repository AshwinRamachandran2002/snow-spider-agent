WITH over_runs AS (
    SELECT  b.match_id,
            b.innings_no,
            b.over_id,
            b.bowler,
            SUM(COALESCE(s.runs_scored,0) + COALESCE(e.extra_runs,0)) AS runs_in_over
    FROM ball_by_ball AS b
    LEFT JOIN batsman_scored AS s
           ON  s.match_id   = b.match_id
           AND s.over_id    = b.over_id
           AND s.ball_id    = b.ball_id
           AND s.innings_no = b.innings_no
    LEFT JOIN extra_runs AS e
           ON  e.match_id   = b.match_id
           AND e.over_id    = b.over_id
           AND e.ball_id    = b.ball_id
           AND e.innings_no = b.innings_no
    GROUP BY b.match_id, b.innings_no, b.over_id, b.bowler
),
max_over_each_match AS (
    SELECT o.*
    FROM over_runs AS o
    JOIN (
        SELECT match_id, MAX(runs_in_over) AS max_runs
        FROM over_runs
        GROUP BY match_id
    ) AS m
      ON m.match_id = o.match_id
     AND m.max_runs = o.runs_in_over
),
ranked AS (
    SELECT  p.player_name AS bowler,
            m.match_id    AS match,
            m.runs_in_over,
            ROW_NUMBER() OVER (ORDER BY m.runs_in_over DESC, m.match_id) AS rn
    FROM max_over_each_match AS m
    JOIN player AS p
      ON p.player_id = m.bowler
)
SELECT bowler,
       match,
       runs_in_over AS runs_conceded_in_over
FROM ranked
WHERE rn <= 3
ORDER BY runs_in_over DESC, match;