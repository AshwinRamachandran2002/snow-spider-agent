WITH all_runs AS (                    -- gather every run, whether off the bat or an extra
    SELECT match_id,
           innings_no,
           over_id,
           runs_scored AS runs
    FROM batsman_scored
    UNION ALL
    SELECT match_id,
           innings_no,
           over_id,
           extra_runs  AS runs
    FROM extra_runs
),
runs_per_over AS (                    -- total runs made in each over (per match & innings)
    SELECT match_id,
           innings_no,
           over_id,
           SUM(runs) AS total_runs
    FROM all_runs
    GROUP BY match_id, innings_no, over_id
),
max_over_each_match AS (              -- overs that achieved the highest total in a match
    SELECT r.match_id,
           r.innings_no,
           r.over_id,
           r.total_runs,
           ( SELECT b.bowler
             FROM ball_by_ball b
             WHERE b.match_id  = r.match_id
               AND b.innings_no = r.innings_no
               AND b.over_id    = r.over_id
             LIMIT 1 ) AS bowler_id
    FROM runs_per_over r
    JOIN (
        SELECT match_id,
               MAX(total_runs) AS max_runs
        FROM runs_per_over
        GROUP BY match_id
    ) m
      ON r.match_id  = m.match_id
     AND r.total_runs = m.max_runs
),
chosen_over_per_match AS (            -- if several overs tie, keep the first one
    SELECT match_id,
           innings_no,
           over_id,
           total_runs,
           bowler_id
    FROM (
        SELECT m.*,
               ROW_NUMBER() OVER (PARTITION BY match_id ORDER BY over_id) AS rn
        FROM max_over_each_match m
    )
    WHERE rn = 1
)
SELECT ROUND(AVG(total_runs * 1.0), 4) AS average_highest_over_runs
FROM   chosen_over_per_match;