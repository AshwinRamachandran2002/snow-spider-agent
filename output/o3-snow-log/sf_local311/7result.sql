/* 1. get the last (championship-deciding) race of every season            */
WITH final_races AS (                  
    SELECT 
        r."year",
        MAX(r."race_id") AS "race_id"
    FROM F1.F1."RACES" r
    GROUP BY r."year"
),

/* 2. constructor points after the final race                              */
constructor_points AS (
    SELECT
        fr."year",
        cs."constructor_id",
        cs."points"                  AS "constructor_points"
    FROM F1.F1."CONSTRUCTOR_STANDINGS" cs
    JOIN final_races fr
      ON cs."race_id" = fr."race_id"
),

/* 3. driver points after the final race, mapped to the constructor they    */
/*    represented that season (via TEAM_DRIVER_RANKS)                       */
driver_points AS (
    SELECT
        fr."year",
        tdr."constructor_id",
        ds."driver_id",
        ds."points"                  AS "driver_points"
    FROM F1.F1."DRIVER_STANDINGS"    ds
    JOIN final_races                 fr
      ON ds."race_id" = fr."race_id"
    JOIN F1.F1."TEAM_DRIVER_RANKS"   tdr
      ON tdr."year"      = fr."year"
     AND tdr."driver_id" = ds."driver_id"
),

/* 4. best (highest-scoring) driver per constructor and season             */
best_driver_points AS (
    SELECT
        "year",
        "constructor_id",
        MAX("driver_points") AS "best_driver_points"
    FROM driver_points
    GROUP BY "year", "constructor_id"
),

/* 5. combine team points with best-driver points                          */
combined AS (
    SELECT
        cp."year",
        cp."constructor_id",
        cp."constructor_points",
        COALESCE(bdp."best_driver_points", 0)               AS "best_driver_points",
        cp."constructor_points"
        + COALESCE(bdp."best_driver_points", 0)             AS "combined_points"
    FROM constructor_points cp
    LEFT JOIN best_driver_points bdp
      ON cp."year"          = bdp."year"
     AND cp."constructor_id"= bdp."constructor_id"
),

/* 6. rank every constructor-year combination by the combined total        */
ranked AS (
    SELECT
        c."year",
        cons."name"                       AS "constructor_name",
        c."combined_points",
        ROW_NUMBER() OVER (
            ORDER BY c."combined_points" DESC NULLS LAST
        )                                 AS "rn"
    FROM combined c
    JOIN F1.F1."CONSTRUCTORS" cons
      ON cons."constructor_id" = c."constructor_id"
)

/* 7. return the overall top-3                                              */
SELECT
    "constructor_name",
    "year",
    "combined_points"
FROM ranked
WHERE "rn" <= 3
ORDER BY "combined_points" DESC NULLS LAST;