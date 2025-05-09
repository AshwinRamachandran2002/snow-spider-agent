/* 1. identify the last (championship-deciding) race of every year */
WITH FINAL_RACES AS (
    SELECT  "year",
            MAX("round") AS "last_round"
    FROM    F1.F1.RACES
    GROUP BY "year"
),
FINAL_RACE_IDS AS (
    SELECT  r."year",
            r."race_id"
    FROM    F1.F1.RACES r
            JOIN FINAL_RACES f
              ON r."year"  = f."year"
             AND r."round" = f."last_round"
),

/* 2. constructor points after the last race of each season */
CONSTRUCTOR_PTS AS (
    SELECT  cs."constructor_id",
            fr."year",
            cs."points"        AS "constructor_points"
    FROM    F1.F1.CONSTRUCTOR_STANDINGS cs
            JOIN FINAL_RACE_IDS fr
              ON cs."race_id" = fr."race_id"
),

/* 3. driver points (final standings) and the constructor they raced for that year */
DRIVER_PTS AS (
    SELECT  tdr."constructor_id",
            fr."year",
            ds."driver_id",
            ds."points"
    FROM    F1.F1.DRIVER_STANDINGS ds
            JOIN FINAL_RACE_IDS fr
              ON ds."race_id" = fr."race_id"
            JOIN F1.F1.TEAM_DRIVER_RANKS tdr      -- links driver ↔ constructor for the given season
              ON tdr."driver_id" = ds."driver_id"
             AND tdr."year"      = fr."year"
),

/* 4. best (highest-scoring) driver per constructor & year */
BEST_DRIVER_PTS AS (
    SELECT  "constructor_id",
            "year",
            MAX("points") AS "best_driver_points"
    FROM    DRIVER_PTS
    GROUP BY "constructor_id", "year"
),

/* 5. combine constructor points with their best driver's points */
COMBINED AS (
    SELECT  c."constructor_id",
            c."year",
            c."constructor_points",
            b."best_driver_points",
            (c."constructor_points" + b."best_driver_points") AS "combined_points"
    FROM    CONSTRUCTOR_PTS   c
            JOIN BEST_DRIVER_PTS b
              ON c."constructor_id" = b."constructor_id"
             AND c."year"          = b."year"
),

/* 6. rank and pick the top-3 constructor-season combinations */
RANKED AS (
    SELECT  *,
            DENSE_RANK() OVER (ORDER BY "combined_points" DESC) AS rk
    FROM    COMBINED
)
SELECT  r."year",
        COALESCE(ce."short_name", co."name") AS "constructor_name",
        r."combined_points",
        r."constructor_points",
        r."best_driver_points"
FROM    RANKED r
        JOIN F1.F1.CONSTRUCTORS             co ON r."constructor_id" = co."constructor_id"
        LEFT JOIN F1.F1.CONSTRUCTORS_EXT    ce ON r."constructor_id" = ce."constructor_id"
WHERE   r.rk <= 3
ORDER BY r."combined_points" DESC NULLS LAST;