WITH
-- 1. runs scored by batsmen per over
batsman_runs_per_over AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        SUM(runs_scored) AS runs
    FROM batsman_scored
    GROUP BY match_id, innings_no, over_id
),
-- 2. extra runs per over
extra_runs_per_over AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        SUM(extra_runs) AS runs
    FROM extra_runs
    GROUP BY match_id, innings_no, over_id
),
-- 3. total (batsman + extras) runs per over
combined_runs_over AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        SUM(runs) AS total_runs
    FROM (
        SELECT match_id, innings_no, over_id, runs FROM batsman_runs_per_over
        UNION ALL
        SELECT match_id, innings_no, over_id, runs FROM extra_runs_per_over
    )
    GROUP BY match_id, innings_no, over_id
),
-- 4. identify the bowler of each over (one bowler per over – take the minimum id to be safe)
bowler_per_over AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        MIN(bowler) AS bowler_id
    FROM ball_by_ball
    GROUP BY match_id, innings_no, over_id
),
-- 5. combine runs with the bowler information
over_with_bowler AS (
    SELECT
        c.match_id,
        c.innings_no,
        c.over_id,
        c.total_runs,
        b.bowler_id
    FROM combined_runs_over c
    JOIN bowler_per_over b
      ON c.match_id  = b.match_id
     AND c.innings_no = b.innings_no
     AND c.over_id    = b.over_id
),
-- 6. per match, keep only the single over that has the greatest total runs
highest_over_per_match AS (
    SELECT *
    FROM (
        SELECT
            o.*,
            ROW_NUMBER() OVER (
                PARTITION BY match_id
                ORDER BY total_runs DESC, innings_no, over_id
            ) AS rn
        FROM over_with_bowler o
    )
    WHERE rn = 1
),
-- 7. calculate the average of the highest‑scoring overs across all matches
average_highest AS (
    SELECT AVG(total_runs) AS avg_highest_over_runs
    FROM highest_over_per_match
)
-- 8. final output: each match’s top-scoring over (with bowler) + overall average
SELECT
    h.match_id,
    h.innings_no,
    h.over_id,
    h.total_runs        AS highest_over_runs,
    h.bowler_id,
    p.player_name       AS bowler_name,
    a.avg_highest_over_runs
FROM highest_over_per_match h
LEFT JOIN player       p ON p.player_id = h.bowler_id
CROSS JOIN average_highest a
ORDER BY h.match_id;