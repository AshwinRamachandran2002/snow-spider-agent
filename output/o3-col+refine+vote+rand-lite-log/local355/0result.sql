WITH driver_races AS (
    SELECT
        res.driver_id,
        r.year,
        r.round,
        res.constructor_id,
        LEAD(r.round)            OVER (PARTITION BY res.driver_id, r.year ORDER BY r.round) AS next_round,
        LEAD(res.constructor_id) OVER (PARTITION BY res.driver_id, r.year ORDER BY r.round) AS next_constructor
    FROM results AS res
    JOIN races   AS r ON r.race_id = res.race_id
),
hiatus AS (
    SELECT
        driver_id,
        year,
        round + 1                 AS first_missed_round,
        next_round - 1            AS last_missed_round,
        (next_round - round - 1)  AS races_missed,
        constructor_id            AS before_constructor,
        next_constructor          AS after_constructor
    FROM driver_races
    WHERE next_round IS NOT NULL
      AND next_round - round > 1        -- at least one race skipped
),
qualified_hiatus AS (
    SELECT *
    FROM hiatus
    WHERE races_missed < 3               -- missed fewer than 3 races
      AND before_constructor <> after_constructor   -- switched teams
)
SELECT
    ROUND(AVG(first_missed_round), 4) AS avg_first_missed_round,
    ROUND(AVG(last_missed_round), 4)  AS avg_last_missed_round
FROM qualified_hiatus;