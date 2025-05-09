WITH final_races AS (          -- last GP of every season
    SELECT r.year,
           r.race_id
    FROM races r
    JOIN (
        SELECT year, MAX(round) AS max_round
        FROM races
        GROUP BY year
    ) mr
      ON r.year  = mr.year
     AND r.round = mr.max_round
),
driver_champs AS (             -- drivers’ points after last GP
    SELECT fr.year,
           ds.driver_id,
           ds.points,
           ROW_NUMBER() OVER (PARTITION BY fr.year
                              ORDER BY ds.points DESC, ds.driver_id) AS rn
    FROM final_races fr
    JOIN driver_standings ds ON ds.race_id = fr.race_id
),
top_drivers AS (               -- one (highest‑scoring) driver per year
    SELECT year, driver_id
    FROM driver_champs
    WHERE rn = 1
),
constructor_champs AS (        -- constructors’ points after last GP
    SELECT fr.year,
           cs.constructor_id,
           cs.points,
           ROW_NUMBER() OVER (PARTITION BY fr.year
                              ORDER BY cs.points DESC, cs.constructor_id) AS rn
    FROM final_races fr
    JOIN constructor_standings cs ON cs.race_id = fr.race_id
),
top_constructors AS (          -- one (highest‑scoring) constructor per year
    SELECT year, constructor_id
    FROM constructor_champs
    WHERE rn = 1
)
SELECT td.year,
       COALESCE(de.full_name, d.forename || ' ' || d.surname) AS driver_full_name,
       ce.name AS constructor_name
FROM top_drivers       td
LEFT JOIN drivers_ext   de ON de.driver_id       = td.driver_id
LEFT JOIN drivers       d  ON d.driver_id        = td.driver_id
JOIN  top_constructors  tc ON tc.year            = td.year
JOIN  constructors_ext  ce ON ce.constructor_id  = tc.constructor_id
ORDER BY td.year;