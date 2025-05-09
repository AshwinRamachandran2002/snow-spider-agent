/*  Top-3 constructor-years by the sum of
    – constructor championship points
    – best (highest-scoring) driver’s points for that constructor
*/
WITH final_races AS (                -- last race of every season
    SELECT
        "year",
        "race_id"
    FROM F1.F1.RACES
    QUALIFY "round" = MAX("round") OVER (PARTITION BY "year")
),

constructor_points AS (              -- constructor championship total
    SELECT
        fr."year",
        cs."constructor_id",
        cs."points" AS "constructor_pts"
    FROM final_races fr
    JOIN F1.F1.CONSTRUCTOR_STANDINGS cs
      ON cs."race_id" = fr."race_id"
),

driver_best AS (                     -- best driver’s season total per constructor
    SELECT
        fr."year",
        r."constructor_id",
        MAX(ds."points") AS "driver_best_pts"
    FROM final_races fr
    JOIN F1.F1.DRIVER_STANDINGS ds      ON ds."race_id"  = fr."race_id"
    JOIN F1.F1.RESULTS          r       ON r."race_id"   = ds."race_id"
                                        AND r."driver_id" = ds."driver_id"
    GROUP BY fr."year", r."constructor_id"
),

combined AS (                        -- sum of the two components
    SELECT
        cp."year",
        cp."constructor_id",
        cp."constructor_pts",
        db."driver_best_pts",
        cp."constructor_pts" + db."driver_best_pts" AS "combined_pts"
    FROM constructor_points cp
    JOIN driver_best       db
      ON db."year" = cp."year"
     AND db."constructor_id" = cp."constructor_id"
)

SELECT
    COALESCE(ce."short_name", c."name") AS "constructor",
    "year",
    "combined_pts"
FROM combined cb
LEFT JOIN F1.F1.CONSTRUCTORS_EXT ce ON ce."constructor_id" = cb."constructor_id"
LEFT JOIN F1.F1.CONSTRUCTORS      c  ON c."constructor_id" = cb."constructor_id"
ORDER BY "combined_pts" DESC NULLS LAST
LIMIT 3;