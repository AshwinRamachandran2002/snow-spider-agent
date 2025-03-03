WITH pit_races AS (
    SELECT "race_id"
    FROM "F1"."F1"."RACES_EXT"
    WHERE "is_pit_data_available" = 1
), grid_positions AS (
    SELECT
        res."race_id",
        0 AS "lap",
        res."driver_id",
        res."grid" AS "position"
    FROM
        "F1"."F1"."RESULTS" res
    WHERE
        res."race_id" IN (SELECT "race_id" FROM pit_races)
), positions AS (
    SELECT
        lp."race_id",
        lp."lap",
        lp."driver_id",
        lp."position"
    FROM
        "F1"."F1"."LAP_POSITIONS" lp
    WHERE
        lp."race_id" IN (SELECT "race_id" FROM pit_races)
), positions_union AS (
    SELECT * FROM positions
    UNION ALL
    SELECT * FROM grid_positions
), positions_prev AS (
    SELECT
        pu."race_id",
        pu."lap" + 1 AS "lap",
        pu."driver_id",
        pu."position" AS "position_prev"
    FROM
        positions_union pu
), driver_positions AS (
    SELECT
        pu."race_id",
        pu."lap",
        pu."driver_id",
        pu."position",
        pp."position_prev"
    FROM
        positions_union pu
    LEFT JOIN
        positions_prev pp
    ON
        pu."race_id" = pp."race_id" AND pu."lap" = pp."lap" AND pu."driver_id" = pp."driver_id"
    WHERE
        pu."lap" >= 1
), overtakes AS (
    SELECT
        dp1."race_id",
        dp1."lap",
        dp1."driver_id" AS "driver_id_overtaker",
        dp2."driver_id" AS "driver_id_overtaken",
        dp1."position_prev" AS "pos_overtaker_prev",
        dp1."position" AS "pos_overtaker",
        dp2."position_prev" AS "pos_overtaken_prev",
        dp2."position" AS "pos_overtaken"
    FROM
        driver_positions dp1
    INNER JOIN
        driver_positions dp2
    ON
        dp1."race_id" = dp2."race_id" AND dp1."lap" = dp2."lap"
        AND dp1."driver_id" <> dp2."driver_id"
    WHERE
        dp1."position_prev" > dp2."position_prev" AND dp1."position" < dp2."position"
), retirements AS (
    SELECT
        "race_id",
        "driver_id",
        "lap"
    FROM
        "F1"."F1"."RETIREMENTS"
), pit_stops AS (
    SELECT
        "race_id",
        "driver_id",
        "lap"
    FROM
        "F1"."F1"."PIT_STOPS"
), overtakes_with_retirements AS (
    SELECT
        o.*,
        r."lap" AS "retirement_lap"
    FROM
        overtakes o
    LEFT JOIN
        retirements r
    ON
        o."race_id" = r."race_id" AND o."driver_id_overtaken" = r."driver_id"
        AND o."lap" = r."lap"
), overtakes_with_pit_stops AS (
    SELECT
        owr.*,
        ps_cur."lap" AS "pit_stop_lap",
        ps_prev."lap" AS "pit_stop_prev_lap"
    FROM
        overtakes_with_retirements owr
    LEFT JOIN
        pit_stops ps_cur
    ON
        owr."race_id" = ps_cur."race_id" AND owr."driver_id_overtaken" = ps_cur."driver_id"
        AND owr."lap" = ps_cur."lap"
    LEFT JOIN
        pit_stops ps_prev
    ON
        owr."race_id" = ps_prev."race_id" AND owr."driver_id_overtaken" = ps_prev."driver_id"
        AND owr."lap" = ps_prev."lap" + 1
), overtakes_with_grid AS (
    SELECT
        owp.*,
        res_overtaker."grid" AS "grid_overtaker",
        res_overtaken."grid" AS "grid_overtaken"
    FROM
        overtakes_with_pit_stops owp
    LEFT JOIN
        "F1"."F1"."RESULTS" res_overtaker
    ON
        owp."race_id" = res_overtaker."race_id" AND owp."driver_id_overtaker" = res_overtaker."driver_id"
    LEFT JOIN
        "F1"."F1"."RESULTS" res_overtaken
    ON
        owp."race_id" = res_overtaken."race_id" AND owp."driver_id_overtaken" = res_overtaken."driver_id"
)
SELECT
    CASE
        WHEN o."retirement_lap" IS NOT NULL THEN 'R'
        WHEN o."pit_stop_lap" IS NOT NULL OR o."pit_stop_prev_lap" IS NOT NULL THEN 'P'
        WHEN o."lap" = 1 AND ABS(o."grid_overtaker" - o."grid_overtaken") <= 2 THEN 'S'
        ELSE 'T'
    END AS "Overtake_Type",
    COUNT(*) AS "Count"
FROM
    overtakes_with_grid o
GROUP BY
    1
ORDER BY
    1;