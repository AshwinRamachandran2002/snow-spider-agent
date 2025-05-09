WITH final_races AS (
    SELECT
        year,
        MAX(round)  AS final_round,
        MAX(race_id) AS final_race_id
    FROM races
    WHERE year >= 2001
    GROUP BY year
),
fewest_points_constructors AS (
    /* constructor(s) of the driver(s) with the fewest positive points each season */
    SELECT DISTINCT
        fr.year,
        r.constructor_id
    FROM final_races fr
    JOIN driver_standings ds
      ON ds.race_id = fr.final_race_id
    JOIN results r
      ON r.race_id  = ds.race_id
     AND r.driver_id = ds.driver_id
    WHERE ds.points > 0
      AND ds.points = (
          SELECT MIN(ds2.points)
          FROM driver_standings ds2
          WHERE ds2.race_id = fr.final_race_id
            AND ds2.points > 0
      )
)
SELECT
    c.name AS constructor,
    COUNT(*) AS seasons_with_lowest_point_scorer
FROM fewest_points_constructors fpc
JOIN constructors c
  ON c.constructor_id = fpc.constructor_id
GROUP BY fpc.constructor_id
ORDER BY seasons_with_lowest_point_scorer DESC,
         constructor
LIMIT 5;