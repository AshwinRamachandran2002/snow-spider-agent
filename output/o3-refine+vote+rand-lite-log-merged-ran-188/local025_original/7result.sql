WITH
-- 1. runs scored by batsmen per over
batsman_over AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        SUM(runs_scored) AS run_part
    FROM batsman_scored
    GROUP BY match_id, innings_no, over_id
),
-- 2. extra runs per over
extras_over AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        SUM(extra_runs) AS run_part
    FROM extra_runs
    GROUP BY match_id, innings_no, over_id
),
-- 3. put both components together
combined_over AS (
    SELECT * FROM batsman_over
    UNION ALL
    SELECT * FROM extras_over
),
-- 4. total runs for every (match, innings, over)
over_totals AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        SUM(run_part) AS total_runs
    FROM combined_over
    GROUP BY match_id, innings_no, over_id
),
-- 5. bowler who delivered the over (normally one bowler per over)
bowler_over AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        MIN(bowler) AS bowler_id          -- MIN used just to pick the unique bowler id
    FROM ball_by_ball
    GROUP BY match_id, innings_no, over_id
),
-- 6. attach bowler to each over‐total record
over_details AS (
    SELECT
        ot.match_id,
        ot.innings_no,
        ot.over_id,
        ot.total_runs,
        bo.bowler_id
    FROM over_totals ot
    LEFT JOIN bowler_over bo
           ON  ot.match_id  = bo.match_id
           AND ot.innings_no = bo.innings_no
           AND ot.over_id    = bo.over_id
),
-- 7. pick the single highest‑scoring over for every match
max_over_per_match AS (
    SELECT *
    FROM (
        SELECT
            od.*,
            ROW_NUMBER() OVER (
                PARTITION BY match_id
                ORDER BY total_runs DESC, innings_no, over_id
            ) AS rn
        FROM over_details od
    )
    WHERE rn = 1
),
-- 8. average of those per‑match maxima
average_highest_over AS (
    SELECT AVG(total_runs) AS avg_highest_over_runs
    FROM   max_over_per_match
)
-- 9. final output: details for every match plus the overall average
SELECT
    m.match_id,
    m.innings_no,
    m.over_id,
    m.bowler_id,
    p.player_name      AS bowler_name,
    m.total_runs       AS highest_over_runs,
    a.avg_highest_over_runs
FROM   max_over_per_match m
LEFT  JOIN player p            ON p.player_id = m.bowler_id
CROSS JOIN average_highest_over a
ORDER BY m.match_id;