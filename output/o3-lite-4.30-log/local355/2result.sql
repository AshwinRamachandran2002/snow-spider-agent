SELECT
    ROUND(AVG(first_round_missed), 4) AS average_first_round,
    ROUND(AVG(last_round_missed), 4)  AS average_last_round
FROM (
    SELECT
        last_round + 1           AS first_round_missed,
        next_first_round - 1     AS last_round_missed
    FROM (
        SELECT
            year,
            driver_id,
            constructor_id,
            last_round,
            LEAD(constructor_id) OVER (PARTITION BY year, driver_id ORDER BY first_round) AS next_constructor_id,
            LEAD(first_round)    OVER (PARTITION BY year, driver_id ORDER BY first_round) AS next_first_round
        FROM drives
    )
    WHERE next_first_round IS NOT NULL
      AND (next_first_round - last_round - 1) BETWEEN 1 AND 2  -- missed 1–2 races
      AND constructor_id <> next_constructor_id                -- switched teams
);