WITH final_rounds AS (   -- identify the last round of every season
    SELECT "year",
           MAX("round") AS "final_round"
    FROM F1.F1.RACES
    GROUP BY "year"
),

team_points AS (         -- team (constructor) points after the final round
    SELECT  cs."constructor_id",
            r."year",
            cs."points"           AS team_points
    FROM    F1.F1.CONSTRUCTOR_STANDINGS cs
    JOIN    F1.F1.RACES            r  ON cs."race_id" = r."race_id"
    JOIN    final_rounds               fr ON r."year" = fr."year"
                                         AND r."round" = fr."final_round"
),

driver_final_points AS ( -- every driver's points after the final round
    SELECT  ds."driver_id",
            r."year",
            ds."points"           AS driver_points
    FROM    F1.F1.DRIVER_STANDINGS ds
    JOIN    F1.F1.RACES            r  ON ds."race_id" = r."race_id"
    JOIN    final_rounds               fr ON r."year" = fr."year"
                                         AND r."round" = fr."final_round"
),

driver_team_assoc AS (   -- which constructor(s) each driver raced for in that year
    SELECT  "constructor_id",
            "driver_id",
            "year"
    FROM    F1.F1.DRIVES
),

best_driver_points AS (  -- best-scoring driver for every constructor & season
    SELECT  dta."constructor_id",
            dta."year",
            MAX(dfp.driver_points) AS best_driver_points
    FROM    driver_team_assoc  dta
    JOIN    driver_final_points dfp
           ON dta."driver_id" = dfp."driver_id"
          AND dta."year"      = dfp."year"
    GROUP BY dta."constructor_id", dta."year"
),

combined AS (            -- add team points to best driver points
    SELECT  tp."constructor_id",
            tp."year",
            tp.team_points,
            bdp.best_driver_points,
            tp.team_points + bdp.best_driver_points AS combined_points
    FROM    team_points        tp
    JOIN    best_driver_points bdp
           ON tp."constructor_id" = bdp."constructor_id"
          AND tp."year"          = bdp."year"
)

SELECT      c."name"   AS constructor_name,
            comb."year",
            comb.combined_points
FROM        combined        comb
JOIN        F1.F1.CONSTRUCTORS c
          ON comb."constructor_id" = c."constructor_id"
ORDER BY    comb.combined_points DESC NULLS LAST
LIMIT 3;