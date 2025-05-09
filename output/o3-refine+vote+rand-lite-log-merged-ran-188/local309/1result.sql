WITH driver_year_points AS (
    SELECT
        r.year,
        ds.driver_id,
        MAX(ds.points) AS total_points
    FROM driver_standings AS ds
    JOIN races            AS r  ON r.race_id = ds.race_id
    GROUP BY r.year, ds.driver_id
),
top_driver AS (
    SELECT
        year,
        driver_id,
        total_points
    FROM (
        SELECT
            dyp.*,
            ROW_NUMBER() OVER (
                PARTITION BY year
                ORDER BY total_points DESC, driver_id
            ) AS rn
        FROM driver_year_points AS dyp
    )
    WHERE rn = 1
),
constructor_year_points AS (
    SELECT
        r.year,
        cs.constructor_id,
        MAX(cs.points) AS total_points
    FROM constructor_standings AS cs
    JOIN races                 AS r ON r.race_id = cs.race_id
    GROUP BY r.year, cs.constructor_id
),
top_constructor AS (
    SELECT
        year,
        constructor_id,
        total_points
    FROM (
        SELECT
            cyp.*,
            ROW_NUMBER() OVER (
                PARTITION BY year
                ORDER BY total_points DESC, constructor_id
            ) AS rn
        FROM constructor_year_points AS cyp
    )
    WHERE rn = 1
)
SELECT
    td.year,
    dr.forename || ' ' || dr.surname   AS driver_full_name,
    td.total_points                    AS driver_points,
    c.name                             AS constructor_name,
    tc.total_points                    AS constructor_points
FROM top_driver      AS td
JOIN drivers         AS dr ON dr.driver_id       = td.driver_id
JOIN top_constructor AS tc ON tc.year            = td.year
JOIN constructors    AS c  ON c.constructor_id   = tc.constructor_id
ORDER BY td.year;