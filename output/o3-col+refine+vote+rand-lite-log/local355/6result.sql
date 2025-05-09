WITH driver_years AS (
    -- every driver-season that has at least one classified result
    SELECT DISTINCT r."year", res."driver_id"
    FROM "results" AS res
    JOIN "races"   AS r ON r."race_id" = res."race_id"
),
calendar AS (
    -- full season calendar for each of those driver-years,
    -- marking whether the driver participated and which constructor was used
    SELECT
        dy."driver_id",
        r."year",
        r."round",
        CASE WHEN res."result_id" IS NULL THEN 0 ELSE 1 END AS "participated",
        res."constructor_id"
    FROM driver_years AS dy
    JOIN "races"        AS r   ON r."year" = dy."year"
    LEFT JOIN "results" AS res ON res."race_id" = r."race_id"
                              AND res."driver_id" = dy."driver_id"
),
misses AS (
    -- every missed round, labelled so consecutive zeros share the same grp value
    SELECT
        "driver_id",
        "year",
        "round",
        "participated",
        "constructor_id",
        "round" - ROW_NUMBER() OVER (PARTITION BY "driver_id", "year" ORDER BY "round") AS grp
    FROM calendar
    WHERE "participated" = 0
),
miss_groups AS (
    -- aggregate consecutive missed-race blocks shorter than 3 GPs
    SELECT
        "driver_id",
        "year",
        grp,
        MIN("round") AS first_round_missed,
        MAX("round") AS last_round_missed,
        COUNT(*)     AS missed_len
    FROM misses
    GROUP BY "driver_id", "year", grp
    HAVING missed_len < 3
),
qualified AS (
    -- for each such block, fetch the constructor before and after the hiatus
    SELECT
        mg.*,
        (
            SELECT "constructor_id"
            FROM calendar
            WHERE "driver_id" = mg."driver_id"
              AND "year"      = mg."year"
              AND "participated" = 1
              AND "round"    < mg.first_round_missed
            ORDER BY "round" DESC
            LIMIT 1
        ) AS pre_team,
        (
            SELECT "constructor_id"
            FROM calendar
            WHERE "driver_id" = mg."driver_id"
              AND "year"      = mg."year"
              AND "participated" = 1
              AND "round"    > mg.last_round_missed
            ORDER BY "round" ASC
            LIMIT 1
        ) AS post_team
    FROM miss_groups AS mg
)
SELECT
    ROUND(AVG(first_round_missed), 4) AS avg_first_round_missed,
    ROUND(AVG(last_round_missed), 4)  AS avg_last_round_missed
FROM qualified
WHERE pre_team IS NOT NULL
  AND post_team IS NOT NULL
  AND pre_team <> post_team;