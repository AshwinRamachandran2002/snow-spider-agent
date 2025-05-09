WITH combined_runs AS (
    /* add up batsman and extra runs per over */
    SELECT  match_id,
            innings_no,
            over_id,
            SUM(run) AS total_runs
    FROM   (
              SELECT match_id,
                     innings_no,
                     over_id,
                     runs_scored AS run
              FROM   batsman_scored
              UNION ALL
              SELECT match_id,
                     innings_no,
                     over_id,
                     extra_runs  AS run
              FROM   extra_runs
           )
    GROUP BY match_id, innings_no, over_id
),
max_over_per_match AS (
    /* pick the single over with the highest total runs in each match */
    SELECT match_id,
           innings_no,
           over_id,
           total_runs
    FROM   (
              SELECT *,
                     ROW_NUMBER() OVER (PARTITION BY match_id
                                        ORDER BY total_runs DESC,
                                                 innings_no,
                                                 over_id) AS rn
              FROM   combined_runs
           )
    WHERE  rn = 1
),
bowler_per_over AS (
    /* identify the (single) bowler of each over */
    SELECT match_id,
           innings_no,
           over_id,
           MIN(bowler) AS bowler_id          -- an over is bowled by one bowler
    FROM   ball_by_ball
    GROUP BY match_id, innings_no, over_id
)
SELECT ROUND(AVG(m.total_runs), 4) AS average_highest_over_runs
FROM   max_over_per_match AS m
JOIN   bowler_per_over   AS b
       ON  m.match_id   = b.match_id
       AND m.innings_no = b.innings_no
       AND m.over_id    = b.over_id;