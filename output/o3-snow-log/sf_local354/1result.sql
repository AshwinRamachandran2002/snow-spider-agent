WITH races_50s AS (
    SELECT 
        "race_id",
        "year",
        "round"
    FROM F1.F1.RACES
    WHERE "year" BETWEEN 1950 AND 1959
), 
results_50s AS (
    SELECT 
        r."year",
        r."round"               AS race_round,
        res."driver_id",
        res."constructor_id"
    FROM F1.F1.RESULTS res
    JOIN races_50s r
          ON res."race_id" = r."race_id"
), 
driver_year_results AS (
    SELECT
        "year",
        "driver_id",
        race_round,
        "constructor_id",
        ROW_NUMBER() OVER (PARTITION BY "year", "driver_id" ORDER BY race_round)       AS rn_first,
        ROW_NUMBER() OVER (PARTITION BY "year", "driver_id" ORDER BY race_round DESC)  AS rn_last,
        COUNT(DISTINCT race_round) OVER (PARTITION BY "year", "driver_id")             AS race_cnt
    FROM results_50s
), 
aggregated AS (
    SELECT
        "year",
        "driver_id",
        MAX(CASE WHEN rn_first = 1 THEN "constructor_id" END) AS first_constructor_id,
        MAX(CASE WHEN rn_last  = 1 THEN "constructor_id" END) AS last_constructor_id,
        MAX(race_cnt)                                         AS race_cnt
    FROM driver_year_results
    GROUP BY "year", "driver_id"
), 
qualified AS (
    SELECT *
    FROM aggregated
    WHERE race_cnt >= 2
      AND first_constructor_id = last_constructor_id
)
SELECT 
    d."full_name"   AS "driver",
    q."year"        AS "season_year",
    c."name"        AS "constructor"
FROM qualified q
JOIN F1.F1.DRIVERS      d ON d."driver_id"      = q."driver_id"
JOIN F1.F1.CONSTRUCTORS c ON c."constructor_id" = q.first_constructor_id
ORDER BY d."full_name", q."year";