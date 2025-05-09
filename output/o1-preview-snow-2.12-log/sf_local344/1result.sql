WITH race_pit AS (
    SELECT "race_id"
    FROM "F1"."F1"."RACES_EXT"
    WHERE "is_pit_data_available" = 1
), 
laps AS (
    SELECT l."race_id", l."lap", l."driver_id", l."position"
    FROM "F1"."F1"."LAP_TIMES_EXT" l
    WHERE l."race_id" IN (SELECT "race_id" FROM race_pit)
), 
laps_with_prev AS (
    SELECT l."race_id", l."lap", l."driver_id", l."position",
        LAG(l."position") OVER (PARTITION BY l."race_id", l."driver_id" ORDER BY l."lap") AS "prev_position"
    FROM laps l
), 
driver_positions AS (
    SELECT lwp.*, r."grid"
    FROM laps_with_prev lwp
    LEFT JOIN "F1"."F1"."RESULTS" r ON lwp."race_id" = r."race_id" AND lwp."driver_id" = r."driver_id"
), 
overtake_candidates AS (
    SELECT dpa."race_id", dpa."lap", dpa."driver_id" AS "driver_a", dpb."driver_id" AS "driver_b",
        dpa."position" AS "position_a", dpb."position" AS "position_b",
        dpa."prev_position" AS "prev_position_a", dpb."prev_position" AS "prev_position_b",
        dpa."grid" AS "grid_a", dpb."grid" AS "grid_b"
    FROM driver_positions dpa
    JOIN driver_positions dpb ON dpa."race_id" = dpb."race_id" AND dpa."lap" = dpb."lap" AND dpa."driver_id" <> dpb."driver_id"
    WHERE (
        (dpa."lap" = 1 AND ABS(dpa."grid" - dpb."grid") <= 2 AND dpa."position" < dpb."position")
        OR
        (dpa."lap" > 1 AND dpa."position" < dpb."position" AND dpa."prev_position" > dpb."prev_position")
    )
), 
overtakes AS (
    SELECT DISTINCT oc."race_id", oc."lap", oc."driver_a", oc."driver_b", oc."grid_a", oc."grid_b"
    FROM overtake_candidates oc
), 
overtakes_classified AS (
    SELECT uo.*, 
    CASE 
        WHEN rt."driver_id" IS NOT NULL THEN 'R'
        WHEN uo."lap" = 1 AND ABS(uo."grid_a" - uo."grid_b") <= 2 THEN 'S'
        WHEN ps_entry."driver_id" IS NOT NULL OR ps_exit."driver_id" IS NOT NULL THEN 'P'
        ELSE 'T'
    END AS "Overtake_Type"
    FROM overtakes uo
    LEFT JOIN "F1"."F1"."RETIREMENTS" rt ON uo."race_id" = rt."race_id" AND uo."lap" = rt."lap" AND uo."driver_b" = rt."driver_id"
    LEFT JOIN "F1"."F1"."PIT_STOPS" ps_entry ON uo."race_id" = ps_entry."race_id" AND uo."lap" = ps_entry."lap" AND uo."driver_b" = ps_entry."driver_id"
    LEFT JOIN "F1"."F1"."PIT_STOPS" ps_exit ON uo."race_id" = ps_exit."race_id" AND uo."lap" = ps_exit."lap" + 1 AND uo."driver_b" = ps_exit."driver_id"
), 
counts AS (
    SELECT "Overtake_Type", COUNT(*) AS "Count"
    FROM overtakes_classified
    GROUP BY "Overtake_Type"
)
SELECT "Overtake_Type", "Count"
FROM counts
ORDER BY "Overtake_Type";