WITH ball_runs AS (                         -- runs conceded on every ball
    SELECT  b.match_id,
            b.over_id,
            b.innings_no,
            b.bowler,
            COALESCE(bs.runs_scored,0) +      -- runs off the bat
            COALESCE(er.extra_runs,0)  AS runs
    FROM   ball_by_ball  AS b
    LEFT JOIN batsman_scored AS bs
           ON  b.match_id  = bs.match_id
           AND b.over_id   = bs.over_id
           AND b.ball_id   = bs.ball_id
           AND b.innings_no= bs.innings_no
    LEFT JOIN extra_runs   AS er
           ON  b.match_id  = er.match_id
           AND b.over_id   = er.over_id
           AND b.ball_id   = er.ball_id
           AND b.innings_no= er.innings_no
),
over_runs AS (                              -- total runs conceded in every over
    SELECT  match_id,
            innings_no,
            over_id,
            MIN(bowler)          AS bowler,     -- exactly one bowler per over
            SUM(runs)            AS total_runs
    FROM    ball_runs
    GROUP BY match_id, innings_no, over_id
),
match_max_over AS (                         -- only overs that were the most expensive in their match
    SELECT  o.*
    FROM    over_runs o
    JOIN   (SELECT match_id,
                   MAX(total_runs) AS max_runs
            FROM   over_runs
            GROUP BY match_id) m
      ON  o.match_id  = m.match_id
      AND o.total_runs= m.max_runs
),
bowler_best_over AS (                       -- a bowler's single worst over from the above set
    SELECT *
    FROM   (
            SELECT mmo.*,
                   ROW_NUMBER() OVER (PARTITION BY bowler
                                      ORDER BY total_runs DESC, match_id) AS rn
            FROM   match_max_over mmo
           )
    WHERE  rn = 1
),
final_ranked AS (                           -- rank bowlers by runs conceded
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY total_runs DESC, match_id) AS rn
    FROM   bowler_best_over
)
SELECT  p.player_name   AS bowler_name,
        f.match_id,
        f.total_runs    AS runs_conceded
FROM    final_ranked f
JOIN    player p
  ON    p.player_id = f.bowler
WHERE   f.rn <= 3
ORDER BY f.total_runs DESC, f.match_id;