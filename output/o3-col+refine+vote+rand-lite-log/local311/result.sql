WITH best_driver_points AS (
    /* points of the single highest-scoring driver for every constructor-season */
    SELECT
        r."year",
        res."constructor_id",
        MAX(ds."points") AS best_driver_points
    FROM "driver_standings"  ds
    JOIN "races"             r   ON r."race_id" = ds."race_id"
    JOIN "results"           res ON res."race_id"   = ds."race_id"
                                AND res."driver_id" = ds."driver_id"
    /* only take the final round of each season */
    WHERE r."round" = (
        SELECT MAX(r2."round")
        FROM "races" r2
        WHERE r2."year" = r."year"
    )
    GROUP BY r."year", res."constructor_id"
),
constructor_totals AS (
    /* constructor’s own season total (taken at the same final race) */
    SELECT
        r."year",
        cs."constructor_id",
        cs."points" AS constructor_points
    FROM "constructor_standings" cs
    JOIN "races"                r ON r."race_id" = cs."race_id"
    WHERE r."round" = (
        SELECT MAX(r2."round")
        FROM "races" r2
        WHERE r2."year" = r."year"
    )
)
SELECT
    c."name" AS constructor_name,
    bd."year",
    (bd.best_driver_points + ct.constructor_points) AS combined_points
FROM best_driver_points bd
JOIN constructor_totals ct
      ON ct."year" = bd."year"
     AND ct."constructor_id" = bd."constructor_id"
JOIN "constructors" c ON c."constructor_id" = bd."constructor_id"
ORDER BY combined_points DESC
LIMIT 3;