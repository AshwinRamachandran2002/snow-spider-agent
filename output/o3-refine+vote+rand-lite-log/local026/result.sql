WITH ball_runs AS (
    /*Runs given on every ball (batsman runs + extras) along with the bowler*/
    SELECT  b.match_id,
            b.innings_no,
            b.over_id,
            b.bowler,
            COALESCE(bs.runs_scored,0) + COALESCE(er.extra_runs,0) AS runs_conceded
    FROM    ball_by_ball AS b
    LEFT JOIN batsman_scored AS bs
           ON  b.match_id  = bs.match_id
           AND b.innings_no= bs.innings_no
           AND b.over_id   = bs.over_id
           AND b.ball_id   = bs.ball_id
    LEFT JOIN extra_runs  AS er
           ON  b.match_id  = er.match_id
           AND b.innings_no= er.innings_no
           AND b.over_id   = er.over_id
           AND b.ball_id   = er.ball_id
),
over_runs AS (
    /*Total runs conceded in every over by the bowler*/
    SELECT  match_id,
            innings_no,
            over_id,
            bowler,
            SUM(runs_conceded) AS runs_in_over
    FROM    ball_runs
    GROUP BY match_id, innings_no, over_id, bowler
),
match_max AS (
    /*Maximum runs conceded in any over of each match*/
    SELECT  match_id,
            MAX(runs_in_over) AS max_runs_in_match
    FROM    over_runs
    GROUP BY match_id
),
match_max_overs AS (
    /*Overs that equal the per‑match maximum*/
    SELECT  o.match_id,
            o.bowler,
            o.runs_in_over
    FROM    over_runs o
    JOIN    match_max m
      ON    o.match_id = m.match_id
     AND    o.runs_in_over = m.max_runs_in_match
),
bowler_best AS (
    /*For every bowler, keep the single (match, over) where he conceded most in a match‑max over*/
    SELECT  bowler,
            runs_in_over,
            match_id,
            ROW_NUMBER() OVER (PARTITION BY bowler 
                               ORDER BY runs_in_over DESC, match_id) AS rn
    FROM    match_max_overs
),
top_bowlers AS (
    /*Pick top 3 bowlers by the runs they gave in that over*/
    SELECT  bowler,
            match_id,
            runs_in_over
    FROM    bowler_best
    WHERE   rn = 1
    ORDER BY runs_in_over DESC
    LIMIT 3
)
SELECT  p.player_name,
        tb.match_id
FROM    top_bowlers tb
JOIN    player p
  ON    p.player_id = tb.bowler
ORDER BY tb.runs_in_over DESC,
         p.player_name;