WITH actor_rental_counts AS (
    SELECT 
        a."actor_id",
        COUNT(r."rental_id") AS "rental_count"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."ACTOR"        a
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR"   fa ON a."actor_id" = fa."actor_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY"    i  ON fa."film_id"  = i."film_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL"       r  ON i."inventory_id" = r."inventory_id"
    GROUP BY a."actor_id"
),
top5_actors AS (           -- five actors with the most rentals
    SELECT "actor_id"
    FROM actor_rental_counts
    ORDER BY "rental_count" DESC NULLS LAST
    LIMIT 5
),
customers_with_top5 AS (   -- every customer who rented at least one film featuring any of those actors
    SELECT DISTINCT r."customer_id"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL"       r
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY"    i  ON r."inventory_id" = i."inventory_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR"   fa ON i."film_id"      = fa."film_id"
    WHERE fa."actor_id" IN (SELECT "actor_id" FROM top5_actors)
),
total_customers AS (
    SELECT COUNT(*) AS "total_cust"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."CUSTOMER"
)
SELECT 
    ROUND(
        100.0 * (SELECT COUNT(*) FROM customers_with_top5) 
        / (SELECT "total_cust"  FROM total_customers), 
        4
    ) AS "pct_of_customers_with_top5_actor_rentals";