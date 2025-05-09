WITH final_races AS (
    SELECT year,
           MAX(round) AS max_round
    FROM races
    GROUP BY year
),
driver_champ AS (
    SELECT year,
           COALESCE(d.full_name, d.forename || ' ' || d.surname) AS driver_name
    FROM (
        SELECT r.year,
               ds.driver_id,
               ROW_NUMBER() OVER (PARTITION BY r.year
                                  ORDER BY ds.points DESC, ds.driver_id) AS rn
        FROM driver_standings AS ds
        JOIN races              AS r  ON r.race_id = ds.race_id
        JOIN final_races        AS fr ON fr.year = r.year
                                     AND fr.max_round = r.round
    ) AS w
    JOIN drivers AS d ON d.driver_id = w.driver_id
    WHERE w.rn = 1
),
constructor_champ AS (
    SELECT year,
           c.name AS constructor_name
    FROM (
        SELECT r.year,
               cs.constructor_id,
               ROW_NUMBER() OVER (PARTITION BY r.year
                                  ORDER BY cs.points DESC, cs.constructor_id) AS rn
        FROM constructor_standings AS cs
        JOIN races                 AS r  ON r.race_id = cs.race_id
        JOIN final_races           AS fr ON fr.year = r.year
                                        AND fr.max_round = r.round
    ) AS w
    JOIN constructors AS c ON c.constructor_id = w.constructor_id
    WHERE w.rn = 1
)
SELECT d.year,
       d.driver_name,
       c.constructor_name
FROM driver_champ      AS d
JOIN constructor_champ AS c USING (year)
ORDER BY d.year;