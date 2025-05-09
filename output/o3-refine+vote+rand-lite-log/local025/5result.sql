WITH
/* 1.  Runs scored by batsmen in every over            */
batsman_over AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        SUM(runs_scored) AS batsman_runs
    FROM batsman_scored
    GROUP BY match_id, innings_no, over_id
),
/* 2.  Extra runs in every over                       */
extra_over AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        SUM(extra_runs) AS extra_runs
    FROM extra_runs
    GROUP BY match_id, innings_no, over_id
),
/* 3.  Bowler who delivered each over (only one per over) */
bowler_over AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        MIN(bowler) AS bowler_id          -- same for all balls in an over
    FROM ball_by_ball
    GROUP BY match_id, innings_no, over_id
),
/* 4.  Combine everything to get total runs per over  */
over_totals AS (
    SELECT
        bo.match_id,
        bo.innings_no,
        bo.over_id,
        COALESCE(b.batsman_runs, 0) AS batsman_runs,
        COALESCE(e.extra_runs,   0) AS extra_runs,
        COALESCE(b.batsman_runs, 0) + COALESCE(e.extra_runs, 0) AS total_runs,
        bo.bowler_id
    FROM bowler_over bo
    LEFT JOIN batsman_over b
           ON b.match_id   = bo.match_id
          AND b.innings_no = bo.innings_no
          AND b.over_id    = bo.over_id
    LEFT JOIN extra_over  e
           ON e.match_id   = bo.match_id
          AND e.innings_no = bo.innings_no
          AND e.over_id    = bo.over_id
),
/* 5.  For each match pick the single highest‑scoring over */
highest_over_per_match AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        bowler_id,
        total_runs,
        ROW_NUMBER() OVER (
            PARTITION BY match_id
            ORDER BY total_runs DESC, innings_no, over_id          -- tie‑breakers
        ) AS rn
    FROM over_totals
)
/* 6.  Compute the average of those highest totals across matches */
SELECT
    ROUND(AVG(total_runs), 4) AS avg_highest_over_runs
FROM highest_over_per_match
WHERE rn = 1;