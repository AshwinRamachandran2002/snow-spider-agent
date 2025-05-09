WITH
-- 1)  Grid-start gains (lap 0 → lap 1)
start_related AS (
    SELECT COUNT(*) AS cnt
    FROM "lap_positions" p0
    JOIN "lap_positions" p1
      ON p1."race_id"   = p0."race_id"
     AND p1."driver_id" = p0."driver_id"
    WHERE p0."lap" = 0
      AND p1."lap" = 1
      AND p1."position" < p0."position"
),

-- 2)  Retirements in laps 1-5
retire_overtakes AS (
    SELECT COUNT(*) AS cnt
    FROM "retirements"
    WHERE "lap" <= 5
),

-- 3)  Places lost immediately after pit-stops in laps 1-5
pit_overtakes AS (
    SELECT COALESCE(SUM(p_next."position" - p_now."position"), 0) AS cnt
    FROM "pit_stops" ps
    JOIN "lap_positions" p_now
      ON p_now."race_id"   = ps."race_id"
     AND p_now."driver_id" = ps."driver_id"
     AND p_now."lap"       = ps."lap"
    JOIN "lap_positions" p_next
      ON p_next."race_id"   = ps."race_id"
     AND p_next."driver_id" = ps."driver_id"
     AND p_next."lap"       = ps."lap" + 1
    WHERE ps."lap" <= 5
      AND p_next."position" > p_now."position"    -- driver lost places ⇒ others gained
),

-- 4)  Standard on-track passes in laps 2-5
standard_on_track AS (
    SELECT COUNT(*) AS cnt
    FROM "lap_positions" prev
    JOIN "lap_positions" curr
      ON curr."race_id"   = prev."race_id"
     AND curr."driver_id" = prev."driver_id"
     AND curr."lap"       = prev."lap" + 1
    WHERE curr."lap" BETWEEN 2 AND 5
      AND curr."position" < prev."position"
)

SELECT
    (SELECT cnt FROM retire_overtakes)   AS "retirement_overtakes",
    (SELECT cnt FROM pit_overtakes)      AS "pit_stop_overtakes",
    (SELECT cnt FROM start_related)      AS "start_related_overtakes",
    (SELECT cnt FROM standard_on_track)  AS "standard_on_track_overtakes";