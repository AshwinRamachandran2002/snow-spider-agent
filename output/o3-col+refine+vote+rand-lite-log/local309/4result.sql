WITH driver_season AS (
    SELECT  r.year,
            ds.driver_id,
            SUM(ds.points) AS driver_points
    FROM   driver_standings AS ds
    JOIN   races            AS r ON r.race_id = ds.race_id
    GROUP  BY r.year, ds.driver_id
),
top_driver AS (
    SELECT  ds.year,
            d.forename || ' ' || d.surname AS driver_full_name,
            ds.driver_points
    FROM  (
              SELECT  year,
                      driver_id,
                      driver_points,
                      RANK() OVER (PARTITION BY year ORDER BY driver_points DESC) AS rk
              FROM    driver_season
          ) AS ds
    JOIN   drivers AS d ON d.driver_id = ds.driver_id
    WHERE  ds.rk = 1
),
constructor_season AS (
    SELECT  r.year,
            cr.constructor_id,
            SUM(cr.points) AS constructor_points
    FROM   constructor_results AS cr
    JOIN   races              AS r ON r.race_id = cr.race_id
    GROUP  BY r.year, cr.constructor_id
),
top_constructor AS (
    SELECT  cs.year,
            c.name AS constructor_name,
            cs.constructor_points
    FROM (
             SELECT  year,
                     constructor_id,
                     constructor_points,
                     RANK() OVER (PARTITION BY year ORDER BY constructor_points DESC) AS rk
             FROM    constructor_season
         ) AS cs
    JOIN   constructors AS c ON c.constructor_id = cs.constructor_id
    WHERE  cs.rk = 1
)
SELECT  td.year,
        td.driver_full_name,
        td.driver_points,
        tc.constructor_name,
        tc.constructor_points
FROM    top_driver      AS td
JOIN    top_constructor AS tc ON tc.year = td.year
ORDER   BY td.year;