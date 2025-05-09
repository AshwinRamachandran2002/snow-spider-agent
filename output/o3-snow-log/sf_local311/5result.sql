WITH final_race_info AS (           -- last round of every season
    SELECT  r."year",
            MAX(r."round")     AS "max_round"
    FROM    F1.F1.RACES r
    GROUP BY r."year"
),
final_race_ids AS (                -- race_id of that last round
    SELECT  r."year",
            r."round"        AS "max_round",
            r."race_id"
    FROM    F1.F1.RACES r
    JOIN    final_race_info f
           ON f."year" = r."year"
          AND f."max_round" = r."round"
),
constructor_totals AS (            -- season-ending constructor points
    SELECT  cs."constructor_id",
            fri."year",
            cs."points"       AS "constructor_points"
    FROM    F1.F1.CONSTRUCTOR_STANDINGS cs
    JOIN    final_race_ids fri
           ON fri."race_id" = cs."race_id"
),
driver_totals AS (                 -- season-ending driver points
    SELECT  ds."driver_id",
            fri."year",
            ds."points"        AS "driver_points",
            fri."max_round"
    FROM    F1.F1.DRIVER_STANDINGS ds
    JOIN    final_race_ids fri
           ON fri."race_id" = ds."race_id"
),
driver_constructor AS (            -- map those drivers to the constructor they
                                   -- were driving for in that final round
    SELECT  dt."driver_id",
            dt."year",
            d."constructor_id",
            dt."driver_points"
    FROM    driver_totals dt
    JOIN    F1.F1.DRIVES d
           ON d."driver_id"   = dt."driver_id"
          AND d."year"        = dt."year"
          AND d."first_round" <= dt."max_round"
          AND d."last_round"  >= dt."max_round"
),
best_driver_per_constructor AS (   -- best driver per constructor & season
    SELECT  dc."constructor_id",
            dc."year",
            MAX(dc."driver_points") AS "best_driver_points"
    FROM    driver_constructor dc
    GROUP BY dc."constructor_id",
             dc."year"
),
combined AS (                      -- combine team points with best driver points
    SELECT  ct."constructor_id",
            ct."year",
            ct."constructor_points",
            bdp."best_driver_points",
            ct."constructor_points" + bdp."best_driver_points" AS "combined_points"
    FROM    constructor_totals ct
    JOIN    best_driver_per_constructor bdp
           ON bdp."constructor_id" = ct."constructor_id"
          AND bdp."year"           = ct."year"
)
SELECT  cext."short_name"  AS "constructor",
        cmb."year",
        cmb."combined_points"
FROM    combined cmb
JOIN    F1.F1.CONSTRUCTORS_EXT cext
       ON cext."constructor_id" = cmb."constructor_id"
ORDER BY cmb."combined_points" DESC NULLS LAST
LIMIT 3;