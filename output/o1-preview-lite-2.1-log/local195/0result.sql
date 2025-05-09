SELECT ROUND(
    (
        (
            SELECT COUNT(DISTINCT "rental"."customer_id")
            FROM "rental"
            JOIN "inventory" ON "rental"."inventory_id" = "inventory"."inventory_id"
            WHERE "inventory"."film_id" IN (
                SELECT DISTINCT "film_actor"."film_id"
                FROM "film_actor"
                WHERE "film_actor"."actor_id" IN (
                    SELECT "actor_id"
                    FROM "film_actor"
                    GROUP BY "actor_id"
                    ORDER BY COUNT("film_id") DESC
                    LIMIT 5
                )
            )
        ) * 100.0 /
        (
            SELECT COUNT(DISTINCT "customer_id")
            FROM "customer"
        )
    ), 4
) AS "Percentage_of_Customers";