WITH ball_runs AS (                 -- runs conceded on every individual ball
    SELECT 
        bb.match_id,
        bb.over_id,
        bb.innings_no,
        bb.bowler,
        (bs.runs_scored + COALESCE(er.extra_runs,0)) AS total_runs_ball
    FROM ball_by_ball   bb
    JOIN batsman_scored bs
          ON  bb.match_id   = bs.match_id
          AND bb.over_id    = bs.over_id
          AND bb.ball_id    = bs.ball_id
          AND bb.innings_no = bs.innings_no
    LEFT JOIN extra_runs   er
          ON  bb.match_id   = er.match_id
          AND bb.over_id    = er.over_id
          AND bb.ball_id    = er.ball_id
          AND bb.innings_no = er.innings_no
),
over_runs AS (                      -- total runs conceded by a bowler in each over
    SELECT
        match_id,
        over_id,
        innings_no,
        bowler,
        SUM(total_runs_ball) AS runs_in_over
    FROM ball_runs
    GROUP BY match_id, over_id, innings_no, bowler
),
match_max AS (                      -- maximum runs conceded in a single over of every match
    SELECT
        match_id,
        MAX(runs_in_over) AS max_runs_in_match
    FROM over_runs
    GROUP BY match_id
),
max_overs AS (                      -- overs which reached that match‑maximum
    SELECT o.*
    FROM over_runs o
    JOIN match_max m
      ON  o.match_id = m.match_id
      AND o.runs_in_over = m.max_runs_in_match
),
bowler_best AS (                    -- each bowler’s best (highest) such over
    SELECT
        bowler,
        MAX(runs_in_over) AS max_runs_conceded
    FROM max_overs
    GROUP BY bowler
),
bowler_best_match AS (              -- pick a match that contains that best over (if many, the first by match_id)
    SELECT
        mo.bowler,
        MIN(mo.match_id) AS match_id,
        bb.max_runs_conceded
    FROM max_overs    mo
    JOIN bowler_best  bb
         ON mo.bowler = bb.bowler
        AND mo.runs_in_over = bb.max_runs_conceded
    GROUP BY mo.bowler
)
SELECT
    p.player_name      AS bowler_name,
    bm.match_id,
    bm.max_runs_conceded AS runs_conceded_in_over
FROM bowler_best_match bm
JOIN player p ON p.player_id = bm.bowler
ORDER BY bm.max_runs_conceded DESC,
         p.player_name
LIMIT 3;