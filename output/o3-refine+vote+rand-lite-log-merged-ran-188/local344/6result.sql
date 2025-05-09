WITH pit_races AS (
    SELECT "race_id"
    FROM   "races_ext"
    WHERE  "is_pit_data_available" = 1
),
/* follower-leader pairs on the CURRENT lap (pos diff = 1) */
pairs_curr AS (
    SELECT lp."race_id",
           lp."lap",
           lp."driver_id"        AS "follower_driver_id",
           lead_lp."driver_id"   AS "leader_driver_id"
    FROM   "lap_positions" lp
    JOIN   "lap_positions" lead_lp
           ON  lead_lp."race_id"  = lp."race_id"
           AND lead_lp."lap"      = lp."lap"
           AND lead_lp."position" = lp."position" - 1
    WHERE  lp."race_id" IN (SELECT "race_id" FROM pit_races)
),
/* the SAME follower-leader pair one LAP EARLIER */
pairs_prev AS (
    SELECT lp."race_id",
           lp."lap" + 1          AS "lap",
           lp."driver_id"        AS "follower_driver_id",
           lead_lp."driver_id"   AS "leader_driver_id"
    FROM   "lap_positions" lp
    JOIN   "lap_positions" lead_lp
           ON  lead_lp."race_id"  = lp."race_id"
           AND lead_lp."lap"      = lp."lap"
           AND lead_lp."position" = lp."position" - 1
),
/* keep ONLY pairs that did NOT exist on previous lap */
new_pairs AS (
    SELECT c.*
    FROM   pairs_curr c
    LEFT   JOIN pairs_prev p
           ON  p."race_id"            = c."race_id"
           AND p."lap"                = c."lap"
           AND p."follower_driver_id" = c."follower_driver_id"
           AND p."leader_driver_id"   = c."leader_driver_id"
    WHERE  p."race_id" IS NULL        -- new pairing
      AND  c."lap" > 0                -- ignore the grid (lap 0)
),
/* classify the reason for the position change */
typed AS (
    SELECT np.*,
           CASE
               WHEN rt."driver_id" IS NOT NULL
                    THEN 'Retirement'
               WHEN ps_lead."driver_id" IS NOT NULL
                 OR ps_foll."driver_id" IS NOT NULL
                    THEN 'Pit-Stop'
               WHEN np."lap" = 1
                    THEN 'Race Start'
               ELSE 'On-Track'
           END AS "overtake_type"
    FROM   new_pairs        np
    LEFT   JOIN "retirements" rt
           ON  rt."race_id" = np."race_id"
           AND rt."lap"     = np."lap"
           AND rt."driver_id" IN (np."leader_driver_id", np."follower_driver_id")
    LEFT   JOIN "pit_stops" ps_lead
           ON  ps_lead."race_id"   = np."race_id"
           AND ps_lead."driver_id" = np."leader_driver_id"
           AND ps_lead."lap"       = np."lap"
    LEFT   JOIN "pit_stops" ps_foll
           ON  ps_foll."race_id"   = np."race_id"
           AND ps_foll."driver_id" = np."follower_driver_id"
           AND ps_foll."lap"       = np."lap"
)
SELECT "overtake_type",
       COUNT(*) AS "num_of_occurrences"
FROM   typed
GROUP  BY "overtake_type"
ORDER BY "num_of_occurrences" DESC;