WITH  extras_per_ball AS (           -- sum every type of extra that happened on a ball
        SELECT  match_id,
                over_id,
                ball_id,
                SUM(extra_runs)      AS extra_runs
        FROM    extra_runs
        GROUP BY match_id, over_id, ball_id
     ),
     bats_per_ball   AS (            -- sum the runs the batsman scored off the ball
        SELECT  match_id,
                over_id,
                ball_id,
                SUM(runs_scored)     AS batsman_runs
        FROM    batsman_scored
        GROUP BY match_id, over_id, ball_id
     ),
     ball_runs AS (                  -- total runs that came off every single ball
        SELECT  bb.match_id,
                bb.over_id,
                bb.ball_id,
                bb.bowler,
                COALESCE(bp.batsman_runs,0) + 
                COALESCE(ep.extra_runs ,0)  AS total_runs
        FROM    ball_by_ball  AS bb
        LEFT JOIN bats_per_ball   AS bp
               ON (bp.match_id ,bp.over_id ,bp.ball_id) =
                  (bb.match_id,bb.over_id,bb.ball_id)
        LEFT JOIN extras_per_ball AS ep
               ON (ep.match_id ,ep.over_id ,ep.ball_id) =
                  (bb.match_id,bb.over_id,bb.ball_id)
     ),
     over_runs AS (                  -- runs conceded in every over by every bowler
        SELECT  match_id,
                bowler,
                over_id,
                SUM(total_runs) AS runs_in_over
        FROM    ball_runs
        GROUP BY match_id, bowler, over_id
     ),
     match_max AS (                  -- the costliest over of each match
        SELECT  match_id,
                MAX(runs_in_over) AS max_runs_in_match
        FROM    over_runs
        GROUP BY match_id
     ),
     candidate_overs AS (            -- keep only those overs that hit the match‑maximum
        SELECT  o.match_id,
                o.bowler,
                o.over_id,
                o.runs_in_over
        FROM    over_runs  AS o
        JOIN    match_max  AS m
              ON m.match_id = o.match_id
             AND m.max_runs_in_match = o.runs_in_over
     )
SELECT  p.player_name   AS bowler_name,
        c.match_id,
        c.runs_in_over  AS runs_conceded
FROM    candidate_overs AS c
JOIN    player          AS p   ON p.player_id = c.bowler
ORDER BY runs_conceded DESC,
         bowler_name
LIMIT 3;