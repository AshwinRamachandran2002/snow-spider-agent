WITH final_races AS (                -- last race of every season
    SELECT  r1."year",
            r1."race_id"
    FROM    F1.F1.RACES r1
    JOIN   (SELECT  "year",
                    MAX("round") AS max_round
             FROM   F1.F1.RACES
             GROUP  BY "year") r2
          ON r1."year"  = r2."year"
         AND r1."round" = r2.max_round
),
constructor_final AS (               -- constructor points after the final race
    SELECT  cs."constructor_id",
            fr."year",
            cs."points" AS constructor_points
    FROM    F1.F1.CONSTRUCTOR_STANDINGS cs
    JOIN    final_races fr
           ON cs."race_id" = fr."race_id"
),
best_driver_per_team AS (             -- best-scoring driver for each constructor/season
    SELECT  d."constructor_id",
            fr."year",
            MAX(ds."points") AS best_driver_points
    FROM    F1.F1.DRIVER_STANDINGS ds
    JOIN    final_races  fr   ON ds."race_id"  = fr."race_id"
    JOIN    F1.F1.DRIVES   d  ON d."driver_id" = ds."driver_id"
                             AND d."year"      = fr."year"
    GROUP BY d."constructor_id",
             fr."year"
),
combined AS (                         -- add constructor & best driver points
    SELECT  cf."constructor_id",
            cf."year",
            cf.constructor_points,
            COALESCE(bd.best_driver_points,0) AS best_driver_points,
            cf.constructor_points + COALESCE(bd.best_driver_points,0) AS combined_points
    FROM    constructor_final cf
    LEFT    JOIN best_driver_per_team bd
           ON cf."constructor_id" = bd."constructor_id"
          AND cf."year"           = bd."year"
)
SELECT  COALESCE(cext."short_name", c."name") AS constructor_name,
        combined."year",
        combined.combined_points,
        combined.constructor_points,
        combined.best_driver_points
FROM    combined
JOIN    F1.F1.CONSTRUCTORS      c     ON c."constructor_id" = combined."constructor_id"
LEFT   JOIN F1.F1.CONSTRUCTORS_EXT cext
                                     ON cext."constructor_id" = combined."constructor_id"
ORDER  BY combined.combined_points DESC NULLS LAST
LIMIT 3;