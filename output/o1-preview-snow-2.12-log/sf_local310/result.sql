SELECT
    "race_id",
    "max_driver_points",
    "max_constructor_points",
    ROUND("max_driver_points" + "max_constructor_points", 4) AS "total"
FROM
    (
        SELECT
            "race_id",
            MAX(driver_points) AS "max_driver_points"
        FROM
            (
                SELECT
                    "race_id",
                    "driver_id",
                    SUM("points") AS driver_points
                FROM
                    F1.F1.RESULTS
                GROUP BY
                    "race_id",
                    "driver_id"
            ) AS driver_totals
        GROUP BY
            "race_id"
    ) AS max_driver_points
JOIN
    (
        SELECT
            "race_id",
            MAX(constructor_points) AS "max_constructor_points"
        FROM
            (
                SELECT
                    "race_id",
                    "constructor_id",
                    SUM("points") AS constructor_points
                FROM
                    F1.F1.RESULTS
                GROUP BY
                    "race_id",
                    "constructor_id"
            ) AS constructor_totals
        GROUP BY
            "race_id"
    ) AS max_constructor_points
USING ("race_id")
ORDER BY
    "total" ASC,
    "race_id" ASC
LIMIT 3;