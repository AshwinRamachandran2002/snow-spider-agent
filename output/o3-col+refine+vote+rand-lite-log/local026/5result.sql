WITH over_runs AS (
    -- runs conceded in every single over
    SELECT
        bb.match_id,
        bb.over_id,
        bb.innings_no,
        bb.bowler,
        SUM(COALESCE(bs.runs_scored,0) + COALESCE(er.extra_runs,0)) AS over_total_runs
    FROM ball_by_ball      AS bb
    LEFT JOIN batsman_scored AS bs
           ON bs.match_id   = bb.match_id
          AND bs.over_id    = bb.over_id
          AND bs.ball_id    = bb.ball_id
          AND bs.innings_no = bb.innings_no
    LEFT JOIN extra_runs     AS er
           ON er.match_id   = bb.match_id
          AND er.over_id    = bb.over_id
          AND er.ball_id    = bb.ball_id
          AND er.innings_no = bb.innings_no
    GROUP BY bb.match_id, bb.over_id, bb.innings_no, bb.bowler
),
match_max AS (
    -- most expensive over of every match
    SELECT
        match_id,
        MAX(over_total_runs) AS max_runs_in_match
    FROM over_runs
    GROUP BY match_id
),
worst_overs AS (
    -- keep only those overs that equal the match maximum
    SELECT o.*
    FROM over_runs o
    JOIN match_max m
      ON m.match_id          = o.match_id
     AND m.max_runs_in_match = o.over_total_runs
)
-- top-3 bowlers who conceded the highest runs in such overs
SELECT
    p.player_name AS bowler_name,
    w.match_id,
    w.over_total_runs
FROM worst_overs w
JOIN player p
  ON p.player_id = w.bowler
ORDER BY w.over_total_runs DESC
LIMIT 3;