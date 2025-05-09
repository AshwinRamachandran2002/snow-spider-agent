WITH ball_details AS (
    SELECT 
        b.match_id,
        b.innings_no,
        b.over_id,
        b.bowler,
        COALESCE(bs.runs_scored,0) + COALESCE(er.extra_runs,0) AS runs
    FROM ball_by_ball AS b
    LEFT JOIN batsman_scored AS bs
         ON bs.match_id   = b.match_id
        AND bs.over_id    = b.over_id
        AND bs.ball_id    = b.ball_id
        AND bs.innings_no = b.innings_no
    LEFT JOIN extra_runs AS er
         ON er.match_id   = b.match_id
        AND er.over_id    = b.over_id
        AND er.ball_id    = b.ball_id
        AND er.innings_no = b.innings_no
),
over_totals AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        bowler,
        SUM(runs) AS over_runs
    FROM ball_details
    GROUP BY match_id, innings_no, over_id, bowler
),
max_per_match AS (
    SELECT
        match_id,
        MAX(over_runs) AS max_runs_in_match
    FROM over_totals
    GROUP BY match_id
),
worst_overs AS (
    SELECT o.*
    FROM over_totals AS o
    JOIN max_per_match AS m
      ON m.match_id = o.match_id
     AND m.max_runs_in_match = o.over_runs
),
ranked AS (
    SELECT
        bowler,
        match_id,
        over_runs,
        ROW_NUMBER() OVER (ORDER BY over_runs DESC, bowler) AS rnk
    FROM worst_overs
)
SELECT
    p.player_name AS bowler,
    r.match_id    AS match,
    r.over_runs   AS runs_conceded_in_over
FROM ranked AS r
JOIN player AS p
  ON p.player_id = r.bowler
WHERE r.rnk <= 3
ORDER BY r.over_runs DESC, p.player_name;