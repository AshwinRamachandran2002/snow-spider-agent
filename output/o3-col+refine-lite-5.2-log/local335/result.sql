WITH driver_season_points AS (          -- total points each driver scored per season
    SELECT ra."year",
           r."driver_id",
           SUM(r."points") AS pts
    FROM   "results" r
    JOIN   "races"   ra ON ra."race_id" = r."race_id"
    WHERE  ra."year" >= 2001
    GROUP  BY ra."year", r."driver_id"
    HAVING pts > 0                                -- ignore zero‑point drivers
),
min_pts_per_season AS (                -- fewest points scored by any point‑scoring driver
    SELECT "year",
           MIN(pts) AS min_pts
    FROM   driver_season_points
    GROUP  BY "year"
),
driver_team_season_pts AS (            -- points each driver scored for every constructor
    SELECT ra."year",
           r."driver_id",
           r."constructor_id",
           SUM(r."points") AS team_pts
    FROM   "results" r
    JOIN   "races"   ra ON ra."race_id" = r."race_id"
    WHERE  ra."year" >= 2001
    GROUP  BY ra."year", r."driver_id", r."constructor_id"
),
primary_team AS (                      -- choose ONE constructor (highest pts, then lowest id)
    SELECT dts."year",
           dts."driver_id",
           MIN(dts."constructor_id") AS constructor_id
    FROM   driver_team_season_pts dts
    JOIN  ( SELECT "year", "driver_id", MAX(team_pts) AS max_pts
            FROM   driver_team_season_pts
            GROUP  BY "year", "driver_id" ) mx
      ON  mx."year"      = dts."year"
      AND mx."driver_id" = dts."driver_id"
      AND mx.max_pts     = dts.team_pts
    GROUP BY dts."year", dts."driver_id"
),
fewest_team AS (                       -- constructor of each “fewest‑points” driver
    SELECT pt."year",
           pt."constructor_id"
    FROM   driver_season_points dsp
    JOIN   min_pts_per_season mp
           ON mp."year" = dsp."year"
          AND mp.min_pts = dsp.pts
    JOIN   primary_team pt
           ON pt."year"      = dsp."year"
          AND pt."driver_id" = dsp."driver_id"
)
SELECT c."name"                        AS constructor,
       COUNT(DISTINCT ft."year")       AS seasons_with_least_pts_driver
FROM   fewest_team ft
JOIN   "constructors" c ON c."constructor_id" = ft."constructor_id"
GROUP  BY c."name"
ORDER  BY seasons_with_least_pts_driver DESC,
          constructor
LIMIT 5;