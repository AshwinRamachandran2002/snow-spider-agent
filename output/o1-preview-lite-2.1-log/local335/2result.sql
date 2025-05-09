SELECT 
    c."constructor_ref",
    counts."seasons_with_fewest_points"
FROM
    (
        SELECT 
            dmc."constructor_id", 
            COUNT(DISTINCT dmc."year") AS "seasons_with_fewest_points"
        FROM
            (
                -- Drivers with minimum total points each year since 2000
                SELECT
                    tp."driver_id",
                    tp."year",
                    tp."total_points"
                FROM
                    (
                        -- Total points per driver per year
                        SELECT
                            res."driver_id",
                            ra."year",
                            SUM(res."points") AS "total_points"
                        FROM
                            "results" res
                        JOIN
                            "races" ra ON res."race_id" = ra."race_id"
                        WHERE
                            ra."year" >= 2000
                        GROUP BY
                            res."driver_id",
                            ra."year"
                    ) tp
                JOIN
                    (
                        -- Minimum total points per year
                        SELECT
                            tp2."year",
                            MIN(tp2."total_points") AS "min_points"
                        FROM
                            (
                                SELECT
                                    res."driver_id",
                                    ra."year",
                                    SUM(res."points") AS "total_points"
                                FROM
                                    "results" res
                                JOIN
                                    "races" ra ON res."race_id" = ra."race_id"
                                WHERE
                                    ra."year" >= 2000
                                GROUP BY
                                    res."driver_id",
                                    ra."year"
                            ) tp2
                        GROUP BY
                            tp2."year"
                    ) mp ON tp."year" = mp."year" AND tp."total_points" = mp."min_points"
            ) dwmp
        JOIN
            (
                -- Determine the constructor each driver was primarily associated with each year
                SELECT
                    dc."driver_id",
                    dc."year",
                    dc."constructor_id"
                FROM
                    (
                        -- Count races per driver per constructor per year
                        SELECT
                            res."driver_id",
                            ra."year",
                            res."constructor_id",
                            COUNT(*) AS "race_count"
                        FROM
                            "results" res
                        JOIN
                            "races" ra ON res."race_id" = ra."race_id"
                        WHERE
                            ra."year" >= 2000
                        GROUP BY
                            res."driver_id",
                            ra."year",
                            res."constructor_id"
                    ) dc
                JOIN
                    (
                        -- Maximum race count per driver per year to find primary constructor
                        SELECT
                            "driver_id",
                            "year",
                            MAX("race_count") AS "max_race_count"
                        FROM
                            (
                                SELECT
                                    res."driver_id",
                                    ra."year",
                                    res."constructor_id",
                                    COUNT(*) AS "race_count"
                                FROM
                                    "results" res
                                JOIN
                                    "races" ra ON res."race_id" = ra."race_id"
                                WHERE
                                    ra."year" >= 2000
                                GROUP BY
                                    res."driver_id",
                                    ra."year",
                                    res."constructor_id"
                            ) dc_inner
                        GROUP BY
                            "driver_id",
                            "year"
                    ) dc_max ON dc."driver_id" = dc_max."driver_id" AND dc."year" = dc_max."year" AND dc."race_count" = dc_max."max_race_count"
            ) dmc ON dwmp."driver_id" = dmc."driver_id" AND dwmp."year" = dmc."year"
        GROUP BY
            dmc."constructor_id"
    ) counts
JOIN 
    "constructors" c ON counts."constructor_id" = c."constructor_id"
ORDER BY 
    counts."seasons_with_fewest_points" DESC,
    c."constructor_ref"
LIMIT 5;