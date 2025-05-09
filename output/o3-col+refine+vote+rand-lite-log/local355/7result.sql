WITH stints AS (
    SELECT
        "year",
        "driver_id",
        "constructor_id",
        "first_round",
        "last_round"
    FROM "drives"
),
gaps AS (
    SELECT
        s1."last_round" + 1                 AS first_missed_round,
        s2."first_round" - 1                AS last_missed_round,
        s2."first_round" - s1."last_round" - 1 AS races_missed
    FROM stints s1
    JOIN stints s2
      ON s1."driver_id" = s2."driver_id"
     AND s1."year"      = s2."year"
     AND s1."last_round" < s2."first_round"
     AND s1."constructor_id" <> s2."constructor_id"
)
SELECT
    ROUND(AVG(first_missed_round),4) AS avg_first_round_missed,
    ROUND(AVG(last_missed_round),4)  AS avg_last_round_missed
FROM gaps
WHERE races_missed BETWEEN 1 AND 2;