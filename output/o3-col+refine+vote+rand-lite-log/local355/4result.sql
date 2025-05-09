WITH appearances AS (
    SELECT
        res.driver_id,
        r.year,
        r.round,
        res.constructor_id,
        LAG(r.round)          OVER (PARTITION BY res.driver_id, r.year ORDER BY r.round) AS prev_round,
        LAG(res.constructor_id) OVER (PARTITION BY res.driver_id, r.year ORDER BY r.round) AS prev_constructor
    FROM results AS res
    JOIN races   AS r ON r.race_id = res.race_id
),
gaps AS (
    SELECT
        (prev_round + 1) AS first_round_missed,
        (round - 1)      AS last_round_missed
    FROM appearances
    WHERE prev_round IS NOT NULL
      AND (round - prev_round - 1) BETWEEN 1 AND 2   -- fewer than three races missed
      AND prev_constructor <> constructor_id         -- constructor changed
)
SELECT
    ROUND(AVG(first_round_missed), 4) AS avg_first_round_missed,
    ROUND(AVG(last_round_missed), 4)  AS avg_last_round_missed
FROM gaps;