WITH over_runs AS (
    SELECT  b.match_id,
            b.over_id,
            b.bowler,
            SUM( COALESCE(bs.runs_scored,0)
               + COALESCE(er.extra_runs ,0))  AS runs_in_over
    FROM ball_by_ball AS b
    LEFT JOIN batsman_scored AS bs
           ON b.match_id = bs.match_id
          AND b.over_id  = bs.over_id
          AND b.ball_id  = bs.ball_id
    LEFT JOIN extra_runs AS er
           ON b.match_id = er.match_id
          AND b.over_id  = er.over_id
          AND b.ball_id  = er.ball_id
    GROUP BY b.match_id, b.over_id, b.bowler
),
match_max AS (                       -- max-run over(s) of every match
    SELECT match_id,
           MAX(runs_in_over) AS max_runs_in_match
    FROM   over_runs
    GROUP BY match_id
),
max_overs AS (                       -- only those overs which were max in their match
    SELECT o.*
    FROM   over_runs o
    JOIN   match_max m
      ON   o.match_id = m.match_id
     AND   o.runs_in_over = m.max_runs_in_match
),
bowler_worst AS (                    -- worst such over for each bowler
    SELECT bowler,
           MAX(runs_in_over) AS worst_runs_conceded
    FROM   max_overs
    GROUP BY bowler
),
top_bowlers AS (                     -- pick top-3 bowlers
    SELECT bowler,
           worst_runs_conceded
    FROM   bowler_worst
    ORDER BY worst_runs_conceded DESC
    LIMIT 3
)
SELECT  p.player_name          AS bowler_name,
        tb.worst_runs_conceded,
        mo.match_id,
        mo.over_id
FROM    top_bowlers tb
JOIN    max_overs  mo
  ON    mo.bowler = tb.bowler
 AND    mo.runs_in_over = tb.worst_runs_conceded
JOIN    player     p
  ON    p.player_id = tb.bowler
ORDER BY tb.worst_runs_conceded DESC,
         bowler_name,
         mo.match_id,
         mo.over_id;