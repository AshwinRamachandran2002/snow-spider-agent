WITH last_races AS (
    SELECT
        year,
        MAX(round) AS last_round
    FROM races
    GROUP BY year
),
final_races AS (
    SELECT
        r.year,
        r.race_id
    FROM races r
    JOIN last_races lr
      ON r.year  = lr.year
     AND r.round = lr.last_round
),
season_top_drivers AS (
    SELECT
        fr.year,
        ds.driver_id,
        ds.points
    FROM final_races fr
    JOIN driver_standings ds
      ON ds.race_id = fr.race_id
    WHERE ds.position = 1          -- champion of the season
),
season_top_constructors AS (
    SELECT
        fr.year,
        cs.constructor_id,
        cs.points
    FROM final_races fr
    JOIN constructor_standings cs
      ON cs.race_id = fr.race_id
    WHERE cs.position = 1          -- champion of the season
)
SELECT
    td.year,
    d.full_name      AS driver_full_name,
    td.points        AS driver_points,
    c.name           AS constructor_name,
    tc.points        AS constructor_points
FROM season_top_drivers      td
JOIN drivers                 d  ON d.driver_id      = td.driver_id
JOIN season_top_constructors tc ON tc.year          = td.year
JOIN constructors            c  ON c.constructor_id = tc.constructor_id
ORDER BY td.year;