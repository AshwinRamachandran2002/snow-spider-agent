WITH final_races AS (           -- last round of every season
    SELECT "year",
           MAX("round") AS final_round
    FROM races
    GROUP BY "year"
),
final_race_ids AS (             -- race_id of that last round
    SELECT r."year",
           r."race_id"
    FROM races r
    JOIN final_races f
      ON r."year"  = f."year"
     AND r."round" = f.final_round
),

/* ------------  DRIVER CHAMPIONS  ------------- */
driver_totals AS (              -- points for every driver after final race
    SELECT fr."year",
           ds.driver_id,
           ds.points
    FROM driver_standings ds
    JOIN final_race_ids fr
      ON ds.race_id = fr.race_id
),
max_driver_points AS (          -- max points per season
    SELECT "year",
           MAX(points) AS max_pts
    FROM driver_totals
    GROUP BY "year"
),
top_drivers AS (                -- all drivers who reached that max (handle ties)
    SELECT dt."year",
           d.forename || ' ' || d.surname AS driver_full_name
    FROM driver_totals dt
    JOIN max_driver_points md
      ON dt."year" = md."year"
     AND dt.points = md.max_pts
    JOIN drivers d
      ON d.driver_id = dt.driver_id
),

/* -----------  CONSTRUCTOR CHAMPIONS ---------- */
constructor_totals AS (         -- points for every constructor after final race
    SELECT fr."year",
           cs.constructor_id,
           cs.points
    FROM constructor_standings cs
    JOIN final_race_ids fr
      ON cs.race_id = fr.race_id
),
max_constructor_points AS (     -- max constructor points per season
    SELECT "year",
           MAX(points) AS max_pts
    FROM constructor_totals
    GROUP BY "year"
),
top_constructors AS (           -- constructors with that max (handle ties)
    SELECT ct."year",
           c.name AS constructor_name
    FROM constructor_totals ct
    JOIN max_constructor_points mc
      ON ct."year" = mc."year"
     AND ct.points = mc.max_pts
    JOIN constructors c
      ON c.constructor_id = ct.constructor_id
)

/* -------------  FINAL RESULT  --------------- */
SELECT td."year",
       td.driver_full_name,
       tc.constructor_name
FROM   top_drivers      td
JOIN   top_constructors tc
  ON   td."year" = tc."year"
ORDER BY td."year";