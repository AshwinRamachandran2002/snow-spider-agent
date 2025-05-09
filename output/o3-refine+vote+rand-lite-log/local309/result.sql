WITH all_driver_points AS (
    /* collect every point scored by each driver in every race (incl. sprints) */
    SELECT  r.year,
            res.driver_id,
            res.points
    FROM    results AS res
    JOIN    races   AS r ON r.race_id = res.race_id
    
    UNION ALL
    
    SELECT  r.year,
            sr.driver_id,
            sr.points
    FROM    sprint_results AS sr
    JOIN    races          AS r ON r.race_id = sr.race_id
),
driver_totals AS (
    SELECT  year,
            driver_id,
            SUM(points) AS total_points
    FROM    all_driver_points
    GROUP BY year,
             driver_id
),
driver_max AS (
    /* choose the top‑scoring driver per season */
    SELECT  year,
            driver_id,
            total_points
    FROM   (
        SELECT  year,
                driver_id,
                total_points,
                ROW_NUMBER() OVER (PARTITION BY year
                                   ORDER BY total_points DESC, driver_id) AS rn
        FROM    driver_totals
    )
    WHERE   rn = 1
),
all_constructor_points AS (
    /* collect every point scored by each constructor in every race (incl. sprints) */
    SELECT  r.year,
            res.constructor_id,
            res.points
    FROM    results AS res
    JOIN    races   AS r ON r.race_id = res.race_id
    
    UNION ALL
    
    SELECT  r.year,
            sr.constructor_id,
            sr.points
    FROM    sprint_results AS sr
    JOIN    races          AS r ON r.race_id = sr.race_id
),
constructor_totals AS (
    SELECT  year,
            constructor_id,
            SUM(points) AS total_points
    FROM    all_constructor_points
    GROUP BY year,
             constructor_id
),
constructor_max AS (
    /* choose the top‑scoring constructor per season */
    SELECT  year,
            constructor_id,
            total_points
    FROM   (
        SELECT  year,
                constructor_id,
                total_points,
                ROW_NUMBER() OVER (PARTITION BY year
                                   ORDER BY total_points DESC, constructor_id) AS rn
        FROM    constructor_totals
    )
    WHERE   rn = 1
)
SELECT  dm.year,
        dr.forename || ' ' || dr.surname AS driver_full_name,
        cr.name                          AS constructor_name
FROM    driver_max      AS dm
JOIN    drivers         AS dr ON dr.driver_id      = dm.driver_id
JOIN    constructor_max AS cm ON cm.year           = dm.year
JOIN    constructors    AS cr ON cr.constructor_id = cm.constructor_id
ORDER BY dm.year;