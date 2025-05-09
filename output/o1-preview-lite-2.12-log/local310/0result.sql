SELECT
    dp.year AS Year,
    ROUND(dp.max_driver_points + cp.max_constructor_points, 4) AS Total_Points
FROM
    (
        SELECT
            year,
            MAX(driver_points) AS max_driver_points
        FROM
            (
                SELECT
                    r.year,
                    res.driver_id,
                    SUM(res.points) AS driver_points
                FROM
                    results res
                    JOIN races r ON res.race_id = r.race_id
                GROUP BY
                    r.year,
                    res.driver_id
            ) driver_year_points
        GROUP BY
            year
    ) dp
    JOIN
    (
        SELECT
            year,
            MAX(constructor_points) AS max_constructor_points
        FROM
            (
                SELECT
                    r.year,
                    res.constructor_id,
                    SUM(res.points) AS constructor_points
                FROM
                    results res
                    JOIN races r ON res.race_id = r.race_id
                GROUP BY
                    r.year,
                    res.constructor_id
                ) constructor_year_points
            GROUP BY
                year
        ) cp ON dp.year = cp.year
ORDER BY
    Total_Points ASC
LIMIT 3;