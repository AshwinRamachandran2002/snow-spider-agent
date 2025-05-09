WITH over_runs AS (                      -- total runs in every over
    SELECT match_id,
           innings_no,
           over_id,
           SUM(runs) AS total_runs
    FROM (
        SELECT match_id,
               innings_no,
               over_id,
               SUM(runs_scored) AS runs
        FROM   batsman_scored
        GROUP  BY match_id, innings_no, over_id
        
        UNION ALL
        
        SELECT match_id,
               innings_no,
               over_id,
               SUM(extra_runs) AS runs
        FROM   extra_runs
        GROUP  BY match_id, innings_no, over_id
    )
    GROUP BY match_id, innings_no, over_id
),

best_over AS (                           -- highest-scoring over per match & innings
    SELECT  match_id,
            innings_no,
            over_id,
            total_runs,
            RANK() OVER (PARTITION BY match_id, innings_no
                         ORDER BY total_runs DESC, over_id) AS rk
    FROM    over_runs
),

best_over_with_bowler AS (               -- attach the bowler of the first ball
    SELECT  bo.match_id,
            bo.innings_no,
            bo.over_id,
            bo.total_runs,
            (
                SELECT bb.bowler
                FROM   ball_by_ball bb
                WHERE  bb.match_id   = bo.match_id
                  AND  bb.innings_no = bo.innings_no
                  AND  bb.over_id    = bo.over_id
                ORDER  BY bb.ball_id
                LIMIT 1
            ) AS bowler_id
    FROM    best_over bo
    WHERE   bo.rk = 1                    -- keep only the single best over
)

SELECT ROUND(AVG(total_runs),4) AS avg_highest_over_runs
FROM   best_over_with_bowler;