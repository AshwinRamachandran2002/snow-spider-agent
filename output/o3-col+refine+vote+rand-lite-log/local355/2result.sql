WITH season_rounds AS (                 -- total number of rounds each season
    SELECT "year", COUNT(*) AS total_rounds
    FROM   "races"
    GROUP  BY "year"
),
driver_seasons AS (                     -- driver-years with < 3 missed races
    SELECT r."year",
           res."driver_id"
    FROM   "results"  res
    JOIN   "races"    r  ON r."race_id" = res."race_id"
    JOIN   season_rounds sr ON sr."year" = r."year"
    GROUP  BY r."year", res."driver_id"
    HAVING sr.total_rounds - COUNT(*) < 3
),
calendar AS (                           -- every round for those driver-years
    SELECT ds."year",
           ds."driver_id",
           ra."round",
           CASE WHEN res."result_id" IS NULL THEN 0 ELSE 1 END AS started,
           res."constructor_id"
    FROM   driver_seasons ds
    JOIN   "races"       ra  ON ra."year" = ds."year"
    LEFT  JOIN "results" res ON res."race_id"  = ra."race_id"
                             AND res."driver_id" = ds."driver_id"
),
ordered AS (                            -- give each row an ordinal per season
    SELECT c.*,
           ROW_NUMBER() OVER (PARTITION BY c."year", c."driver_id"
                              ORDER BY c."round")                  AS rn
    FROM   calendar c
),
missed_rows AS (                        -- only the races that were skipped
    SELECT *,
           ("round" - rn) AS grp_id     -- gap-and-island helper
    FROM   ordered
    WHERE  started = 0
),
hiatuses AS (                           -- consecutive skipped-race segments
    SELECT "year",
           "driver_id",
           MIN("round") AS first_missed_round,
           MAX("round") AS last_missed_round
    FROM   missed_rows
    GROUP  BY "year", "driver_id", grp_id
),
with_constructors AS (                  -- constructor before / after hiatus
    SELECT h.*,
           (SELECT c."constructor_id"
            FROM   calendar c
            WHERE  c."year"      = h."year"
              AND  c."driver_id" = h."driver_id"
              AND  c."round"     = h.first_missed_round - 1
              AND  c.started     = 1
            LIMIT 1)                         AS constructor_before,
           (SELECT c."constructor_id"
            FROM   calendar c
            WHERE  c."year"      = h."year"
              AND  c."driver_id" = h."driver_id"
              AND  c."round"     > h.last_missed_round
              AND  c.started     = 1
            ORDER  BY c."round"
            LIMIT 1)                         AS constructor_after
    FROM   hiatuses h
),
qualified_hiatuses AS (                 -- apply team-switch condition
    SELECT *,
           (last_missed_round - first_missed_round + 1) AS hiatus_len
    FROM   with_constructors
    WHERE  constructor_before IS NOT NULL
      AND  constructor_after  IS NOT NULL
      AND  constructor_before <> constructor_after
)
SELECT ROUND(AVG(first_missed_round), 4) AS avg_first_missed_round,
       ROUND(AVG(last_missed_round),  4) AS avg_last_missed_round
FROM   qualified_hiatuses;