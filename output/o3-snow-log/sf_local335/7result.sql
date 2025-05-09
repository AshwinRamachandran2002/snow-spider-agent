WITH final_races AS (         /* last Grand Prix of every season since 2001 */
    SELECT 
        r."year",
        MAX(r."round") AS max_round
    FROM F1.F1.RACES r
    WHERE r."year" >= 2001
    GROUP BY r."year"
),
season_final_races AS (
    SELECT 
        r."year",
        r."race_id",
        r."round"
    FROM F1.F1.RACES r
    JOIN final_races fr
      ON fr."year" = r."year" 
     AND fr.max_round = r."round"
),
driver_points AS (            /* total season points for every point-scoring driver */
    SELECT
        sfr."year",
        ds."driver_id",
        ds."points",
        d."constructor_id"
    FROM season_final_races sfr
    JOIN F1.F1.DRIVER_STANDINGS ds
      ON ds."race_id" = sfr."race_id"
    JOIN F1.F1.DRIVES d                     -- constructor at the final GP
      ON d."driver_id" = ds."driver_id"
     AND d."year"       = sfr."year"
     AND sfr."round" BETWEEN d."first_round" AND d."last_round"
    WHERE ds."points" > 0                   -- only drivers who scored points
),
min_points AS (               /* minimum points among point-scorers each season */
    SELECT
        "year",
        MIN("points") AS min_points
    FROM driver_points
    GROUP BY "year"
),
worst_constructors AS (       /* constructors whose driver(s) had that minimum */
    SELECT DISTINCT
        dp."year",
        dp."constructor_id"
    FROM driver_points dp
    JOIN min_points mp
      ON mp."year"      = dp."year"
     AND mp.min_points  = dp."points"
)
SELECT 
    COALESCE(ce."short_name", c."name")      AS "constructor",
    COUNT(*)                                 AS "seasons_with_fewest_points_driver"
FROM worst_constructors wc
JOIN F1.F1.CONSTRUCTORS c
  ON c."constructor_id" = wc."constructor_id"
LEFT JOIN F1.F1.CONSTRUCTORS_EXT ce          -- prettier short names when available
  ON ce."constructor_id" = c."constructor_id"
GROUP BY COALESCE(ce."short_name", c."name")
ORDER BY "seasons_with_fewest_points_driver" DESC NULLS LAST,
         "constructor"
LIMIT 5;