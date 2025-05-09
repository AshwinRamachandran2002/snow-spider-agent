WITH driver_totals AS (
    SELECT   r.year,
             res.driver_id,
             SUM(res.points) AS total_points
    FROM     results   res
    JOIN     races     r   ON r.race_id = res.race_id
    GROUP BY r.year, res.driver_id
),
top_driver AS (
    /* drivers with the highest season points each year */
    SELECT dt.*
    FROM   driver_totals dt
    JOIN  (
        SELECT year, MAX(total_points) AS max_points
        FROM   driver_totals
        GROUP BY year
    ) mx ON mx.year = dt.year
         AND mx.max_points = dt.total_points
),
constructor_totals AS (
    SELECT   r.year,
             cr.constructor_id,
             SUM(cr.points) AS total_points
    FROM     constructor_results cr
    JOIN     races             r  ON r.race_id = cr.race_id
    GROUP BY r.year, cr.constructor_id
),
top_constructor AS (
    /* constructors with the highest season points each year */
    SELECT ct.*
    FROM   constructor_totals ct
    JOIN  (
        SELECT year, MAX(total_points) AS max_points
        FROM   constructor_totals
        GROUP BY year
    ) mx ON mx.year = ct.year
         AND mx.max_points = ct.total_points
)

SELECT  td.year,
        COALESCE(de.full_name, d.forename || ' ' || d.surname)  AS driver_name,
        COALESCE(ce.short_name, ce.name, c.name)               AS constructor_name
FROM    top_driver      td
JOIN    drivers         d   ON d.driver_id = td.driver_id
LEFT    JOIN drivers_ext     de ON de.driver_id = td.driver_id
JOIN    top_constructor tc  ON tc.year = td.year
JOIN    constructors    c   ON c.constructor_id = tc.constructor_id
LEFT    JOIN constructors_ext ce ON ce.constructor_id = tc.constructor_id
ORDER BY td.year;