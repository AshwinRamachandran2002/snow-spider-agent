WITH driver_totals AS (           -- points each driver scored in a season
    SELECT ra."year",
           r."driver_id",
           SUM(r."points") AS total_pts
    FROM   "results" r
    JOIN   "races"   ra USING ("race_id")
    WHERE  ra."year" >= 2001
    GROUP  BY ra."year", r."driver_id"
    HAVING total_pts > 0                       -- keep only point-scorers
),
min_pts AS (                       -- minimum positive total per season
    SELECT "year",
           MIN(total_pts) AS min_positive_pts
    FROM   driver_totals
    GROUP  BY "year"
),
driver_cons AS (                   -- driver’s points for every constructor
    SELECT ra."year",
           r."driver_id",
           r."constructor_id",
           SUM(r."points") AS pts_for_constructor
    FROM   "results" r
    JOIN   "races"   ra USING ("race_id")
    WHERE  ra."year" >= 2001
    GROUP  BY ra."year", r."driver_id", r."constructor_id"
),
driver_min_pts AS (                -- drivers who have that seasonal minimum
    SELECT dt."year",
           dt."driver_id"
    FROM   driver_totals dt
    JOIN   min_pts      mp
      ON   mp."year" = dt."year"
     AND   mp.min_positive_pts = dt.total_pts
),
driver_min_cons AS (               -- choose the constructor that “owns” them
    SELECT dmp."year",
           dc."constructor_id",
           ROW_NUMBER() OVER (
               PARTITION BY dmp."year", dmp."driver_id"
               ORDER BY dc.pts_for_constructor DESC, dc."constructor_id"
           ) AS rn
    FROM   driver_min_pts dmp
    JOIN   driver_cons   dc
      ON   dc."year"      = dmp."year"
     AND   dc."driver_id" = dmp."driver_id"
)
SELECT COALESCE(scn."short_name", c."name") AS constructor_name,
       COUNT(DISTINCT dmc."year")           AS seasons_with_lowest_scorer
FROM   driver_min_cons          dmc
JOIN   "constructors"           c   ON c."constructor_id" = dmc."constructor_id"
LEFT   JOIN "short_constructor_names" scn
       ON scn."constructor_ref" = c."constructor_ref"
WHERE  dmc.rn = 1                          -- one constructor per driver-year
GROUP  BY c."constructor_id"
ORDER  BY seasons_with_lowest_scorer DESC, constructor_name
LIMIT 5;