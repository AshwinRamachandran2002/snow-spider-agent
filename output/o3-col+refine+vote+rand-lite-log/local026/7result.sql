WITH over_runs AS (
    /* runs conceded by every bowler in every over */
    SELECT
        b.match_id,
        b.innings_no,
        b.over_id,
        b.bowler,
        SUM(COALESCE(bs.runs_scored,0) + COALESCE(er.extra_runs,0)) AS runs_conceded
    FROM ball_by_ball AS b
    LEFT JOIN batsman_scored AS bs
           ON  b.match_id   = bs.match_id
           AND b.over_id    = bs.over_id
           AND b.ball_id    = bs.ball_id
           AND b.innings_no = bs.innings_no
    LEFT JOIN extra_runs    AS er
           ON  b.match_id   = er.match_id
           AND b.over_id    = er.over_id
           AND b.ball_id    = er.ball_id
           AND b.innings_no = er.innings_no
    GROUP BY
        b.match_id, b.innings_no, b.over_id, b.bowler
),
match_max AS (
    /* most expensive over (runs_conceded) in every match */
    SELECT
        match_id,
        MAX(runs_conceded) AS max_runs_over
    FROM over_runs
    GROUP BY match_id
),
worst_overs AS (
    /* overs that were the most expensive in their respective matches */
    SELECT
        o.match_id,
        o.bowler,
        o.runs_conceded
    FROM over_runs AS o
    JOIN match_max AS m
      ON  o.match_id      = m.match_id
      AND o.runs_conceded = m.max_runs_over
)
SELECT
    p.player_name AS bowler_name,
    w.match_id,
    w.runs_conceded
FROM worst_overs AS w
JOIN player      AS p
  ON p.player_id = w.bowler
ORDER BY
    w.runs_conceded DESC,
    p.player_name
LIMIT 3;