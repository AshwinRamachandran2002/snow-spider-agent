WITH lap_positions AS (
    SELECT "race_id", "lap", "driver_id", "position"
    FROM F1.F1.LAP_TIMES
    WHERE "lap" BETWEEN 1 AND 5
),
driver_positions AS (
    SELECT
        "race_id",
        "lap",
        "driver_id",
        "position",
        LAG("position") OVER (PARTITION BY "race_id", "driver_id" ORDER BY "lap") AS "position_prev"
    FROM lap_positions
),
overtakes AS (
    SELECT DISTINCT
        dp1."race_id",
        dp1."lap",
        dp1."driver_id" AS "driver_id_1",
        dp2."driver_id" AS "driver_id_2",
        dp1."position_prev" AS "position_prev_1",
        dp2."position_prev" AS "position_prev_2",
        dp1."position" AS "position_1",
        dp2."position" AS "position_2"
    FROM driver_positions dp1
    JOIN driver_positions dp2
        ON dp1."race_id" = dp2."race_id"
        AND dp1."lap" = dp2."lap"
        AND dp1."driver_id" <> dp2."driver_id"
    WHERE
        dp1."position_prev" > dp2."position_prev" -- D1 was behind D2 in previous lap
        AND dp1."position" < dp2."position"      -- D1 is ahead of D2 in current lap
        AND dp1."position_prev" IS NOT NULL
        AND dp2."position_prev" IS NOT NULL
),
retirements AS (
    SELECT "race_id", "driver_id", "lap"
    FROM F1.F1.RETIREMENTS
),
pit_stops AS (
    SELECT "race_id", "driver_id", "lap"
    FROM F1.F1.PIT_STOPS
),
results AS (
    SELECT "race_id", "driver_id", "grid"
    FROM F1.F1.RESULTS
)
SELECT
    ot."Type",
    COUNT(*) AS "Number_of_Overtakes"
FROM (
    SELECT
        o."race_id",
        o."lap",
        o."driver_id_1",
        o."driver_id_2",
        o."position_prev_1",
        o."position_prev_2",
        o."position_1",
        o."position_2",
        CASE
            WHEN r."driver_id" IS NOT NULL THEN 'R'
            WHEN p."driver_id" IS NOT NULL THEN 'P'
            WHEN o."lap" = 1 AND res1."grid" IS NOT NULL AND res2."grid" IS NOT NULL AND ABS(res1."grid" - res2."grid") <=2 THEN 'S'
            ELSE 'T'
        END AS "Type"
    FROM overtakes o
    LEFT JOIN retirements r
        ON o."race_id" = r."race_id"
        AND o."driver_id_2" = r."driver_id"
        AND o."lap" = r."lap"
    LEFT JOIN pit_stops p
        ON o."race_id" = p."race_id"
        AND o."driver_id_2" = p."driver_id"
        AND (o."lap" = p."lap" OR o."lap" -1 = p."lap")
    LEFT JOIN results res1
        ON o."race_id" = res1."race_id" AND o."driver_id_1" = res1."driver_id"
    LEFT JOIN results res2
        ON o."race_id" = res2."race_id" AND o."driver_id_2" = res2."driver_id"
) ot
GROUP BY ot."Type"
ORDER BY ot."Type";