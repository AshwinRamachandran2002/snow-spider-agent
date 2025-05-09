WITH actor_rental_counts AS (   -- rentals per actor
    SELECT
        fa."actor_id",
        COUNT(r."rental_id") AS "rental_cnt"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR"  fa
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY"   i ON fa."film_id"     = i."film_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL"      r ON i."inventory_id" = r."inventory_id"
    GROUP BY fa."actor_id"
),
top5_actors AS (               -- pick the five most-rented actors
    SELECT "actor_id"
    FROM actor_rental_counts
    ORDER BY "rental_cnt" DESC NULLS LAST
    LIMIT 5
),
customers_top5 AS (            -- every customer who rented at least one film by those actors
    SELECT DISTINCT
        r."customer_id"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR"  fa
    JOIN top5_actors                                 t  ON fa."actor_id"    = t."actor_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY"   i ON fa."film_id"     = i."film_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL"      r ON i."inventory_id" = r."inventory_id"
),
totals AS (                   -- overall counts
    SELECT 
        (SELECT COUNT(*) FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."CUSTOMER")  AS "total_customers",
        (SELECT COUNT(*) FROM customers_top5)                              AS "top5_customers"
)
SELECT
    "top5_customers",
    "total_customers",
    ROUND(("top5_customers" * 100.0) / "total_customers", 2) AS "pct_customers_top5_actors"
FROM totals;