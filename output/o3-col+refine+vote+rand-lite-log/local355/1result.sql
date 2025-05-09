WITH driver_races AS (
    SELECT
        res."driver_id",
        r."year",
        r."round",
        res."constructor_id",
        ROW_NUMBER() OVER (
            PARTITION BY res."driver_id", r."year"
            ORDER BY r."round"
        ) AS rn
    FROM "results" AS res
    JOIN "races"   AS r ON r."race_id" = res."race_id"
),
gaps AS (
    SELECT
        d1."driver_id",
        d1."year",
        d1."round"            AS prev_round,
        d1."constructor_id"   AS prev_team,
        d2."round"            AS next_round,
        d2."constructor_id"   AS next_team,
        (d2."round" - d1."round" - 1) AS races_missed
    FROM driver_races d1
    JOIN driver_races d2
         ON d1."driver_id" = d2."driver_id"
        AND d1."year"      = d2."year"
        AND d1."rn" + 1    = d2."rn"
    WHERE (d2."round" - d1."round" - 1) BETWEEN 1 AND 2   -- fewer than 3 missed
      AND d1."constructor_id" <> d2."constructor_id"      -- team switch
),
missed AS (
    SELECT
        (prev_round + 1) AS first_missed_round,
        (next_round - 1) AS last_missed_round
    FROM gaps
)
SELECT
    ROUND(AVG(first_missed_round), 4) AS avg_first_missed_round,
    ROUND(AVG(last_missed_round), 4)  AS avg_last_missed_round
FROM missed;