WITH "FINAL_RACES" AS (          -- last GP of every season
    SELECT
        r."year",
        r."race_id"
    FROM F1.F1.RACES r
    QUALIFY r."round" = MAX(r."round") OVER (PARTITION BY r."year")
),

/*  constructor’s season-total points (standing after final race) */
"CONSTRUCTOR_POINTS" AS (
    SELECT
        fr."year",
        cs."constructor_id",
        cs."points"                           AS "constructor_points"
    FROM F1.F1.CONSTRUCTOR_STANDINGS cs
    JOIN "FINAL_RACES" fr
          ON cs."race_id" = fr."race_id"
),

/*  every driver’s season-total points and the team(s) they drove for
    (a driver may appear for several constructors if he switched)        */
"DRIVER_POINTS" AS (
    SELECT
        fr."year",
        d."constructor_id",
        ds."driver_id",
        ds."points"                          AS "driver_points"
    FROM F1.F1.DRIVER_STANDINGS ds
    JOIN "FINAL_RACES" fr
          ON ds."race_id" = fr."race_id"
    JOIN F1.F1.DRIVES d
          ON d."year"      = fr."year"
         AND d."driver_id" = ds."driver_id"
),

/*  best (highest-scoring) driver for every constructor & year */
"BEST_DRIVER_POINTS" AS (
    SELECT
        "year",
        "constructor_id",
        MAX("driver_points")                 AS "best_driver_points"
    FROM "DRIVER_POINTS"
    GROUP BY "year", "constructor_id"
),

/*  combine constructor points with its best driver’s points */
"COMBINED" AS (
    SELECT
        cp."year",
        cp."constructor_id",
        cp."constructor_points",
        COALESCE(bdp."best_driver_points",0)                AS "driver_points",
        cp."constructor_points" +
        COALESCE(bdp."best_driver_points",0)                AS "combined_points"
    FROM "CONSTRUCTOR_POINTS" cp
    LEFT JOIN "BEST_DRIVER_POINTS" bdp
           ON  cp."year"          = bdp."year"
          AND cp."constructor_id" = bdp."constructor_id"
)

/*  top-3 (constructor, year) combinations by combined points */
SELECT
    cst."name"                 AS "constructor_name",
    cmb."year",
    cmb."combined_points"
FROM "COMBINED" cmb
JOIN F1.F1.CONSTRUCTORS cst
      ON cst."constructor_id" = cmb."constructor_id"
ORDER BY cmb."combined_points" DESC NULLS LAST
LIMIT 3;