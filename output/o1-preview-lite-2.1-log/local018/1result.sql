SELECT
    ROUND(
        (
            (
                (
                    (SELECT COUNT(*) FROM "collisions" WHERE "collision_date" LIKE '%2011%' AND "primary_collision_factor" = (
                        SELECT "primary_collision_factor"
                        FROM "collisions"
                        WHERE "collision_date" LIKE '%2021%'
                        GROUP BY "primary_collision_factor"
                        ORDER BY COUNT(*) DESC
                        LIMIT 1
                    )) * 1.0 / (SELECT COUNT(*) FROM "collisions" WHERE "collision_date" LIKE '%2011%')
                ) - 
                (
                    (SELECT COUNT(*) FROM "collisions" WHERE "collision_date" LIKE '%2021%' AND "primary_collision_factor" = (
                        SELECT "primary_collision_factor"
                        FROM "collisions"
                        WHERE "collision_date" LIKE '%2021%'
                        GROUP BY "primary_collision_factor"
                        ORDER BY COUNT(*) DESC
                        LIMIT 1
                    )) * 1.0 / (SELECT COUNT(*) FROM "collisions" WHERE "collision_date" LIKE '%2021%')
                )
            ) * 100
        ), 4
    ) AS "Percentage_decrease";