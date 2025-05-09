WITH final_races AS (        -- last round of each season from 2001 onwards
    SELECT r."race_id",
           r."year"
    FROM   F1.F1.RACES_EXT AS r
    JOIN  (
            SELECT "year",
                   MAX("round") AS "final_round"
            FROM   F1.F1.RACES_EXT
            WHERE  "year" >= 2001
            GROUP  BY "year"
          ) AS f
      ON  r."year"  = f."year"
     AND  r."round" = f."final_round"
),
driver_points AS (           -- final-standing points for every driver (>0)
    SELECT ds."driver_id",
           ds."points",
           fr."year"
    FROM   F1.F1.DRIVER_STANDINGS AS ds
    JOIN   final_races            AS fr
      ON   ds."race_id" = fr."race_id"
    WHERE  ds."points" > 0
),
min_points_per_year AS (      -- minimum points scored by any point scorer
    SELECT "year",
           MIN("points") AS min_points
    FROM   driver_points
    GROUP  BY "year"
),
min_point_drivers AS (        -- drivers who had that minimum
    SELECT dp."driver_id",
           dp."year"
    FROM   driver_points       AS dp
    JOIN   min_points_per_year AS mp
      ON   dp."year"   = mp."year"
     AND   dp."points" = mp.min_points
),
constructor_seasons AS (      -- constructors those drivers raced for
    SELECT DISTINCT
           d."constructor_id",
           d."year"
    FROM   F1.F1.DRIVES      AS d
    JOIN   min_point_drivers AS md
      ON   d."driver_id" = md."driver_id"
     AND   d."year"      = md."year"
),
constructor_counts AS (       -- how many seasons each constructor appears
    SELECT "constructor_id",
           COUNT(*) AS seasons_with_fewest_points
    FROM   constructor_seasons
    GROUP  BY "constructor_id"
)
SELECT COALESCE(ce."short_name", c."name") AS "constructor_name",
       cc.seasons_with_fewest_points
FROM   constructor_counts    AS cc
JOIN   F1.F1.CONSTRUCTORS    AS c
  ON   cc."constructor_id" = c."constructor_id"
LEFT  JOIN F1.F1.CONSTRUCTORS_EXT AS ce
  ON   cc."constructor_id" = ce."constructor_id"
ORDER BY cc.seasons_with_fewest_points DESC NULLS LAST,
         "constructor_name"
LIMIT 5;