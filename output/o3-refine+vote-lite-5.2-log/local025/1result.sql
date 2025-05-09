WITH over_runs AS (
    /* 1.  Runs scored per (match, innings, over) combining batsmen & extras */
    SELECT
        match_id,
        innings_no,
        over_id,
        SUM(runs) AS total_runs
    FROM (
        SELECT
            match_id,
            innings_no,
            over_id,
            runs_scored AS runs
        FROM batsman_scored
        
        UNION ALL
        
        SELECT
            match_id,
            innings_no,
            over_id,
            extra_runs AS runs
        FROM extra_runs
    ) AS all_runs
    GROUP BY
        match_id,
        innings_no,
        over_id
),
max_over AS (
    /* 2.  Pick, for every match, the single over that yielded the most runs  */
    SELECT
        match_id,
        innings_no,
        over_id,
        total_runs,
        ROW_NUMBER() OVER (
            PARTITION BY match_id
            ORDER BY total_runs DESC, innings_no, over_id
        ) AS rn
    FROM over_runs
),
match_max AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        total_runs
    FROM max_over
    WHERE rn = 1
),
match_max_bowler AS (
    /* 3.  Attach the bowler (first ball of that over is enough ‑ same bowler for the over) */
    SELECT
        mm.match_id,
        mm.innings_no,
        mm.over_id,
        mm.total_runs,
        (
            SELECT bowler
            FROM ball_by_ball AS b
            WHERE b.match_id  = mm.match_id
              AND b.innings_no = mm.innings_no
              AND b.over_id    = mm.over_id
            ORDER BY b.ball_id
            LIMIT 1
        ) AS bowler_id
    FROM match_max AS mm
),
average_calc AS (
    /* 4.  Average of the highest‑scoring overs across all matches */
    SELECT AVG(total_runs) AS avg_highest_over_runs
    FROM match_max
)

/* 5.  Final output: details per match + overall average */
SELECT
    mmb.match_id,
    mmb.innings_no,
    mmb.over_id,
    mmb.bowler_id,
    mmb.total_runs  AS highest_over_runs,
    ac.avg_highest_over_runs
FROM match_max_bowler AS mmb
CROSS JOIN average_calc AS ac
ORDER BY mmb.match_id;