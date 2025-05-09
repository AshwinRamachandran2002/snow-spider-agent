WITH top_actors AS (                                   -- 1. five most-featured actors
    SELECT "actor_id"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR"
    GROUP BY "actor_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 5
),
films_top AS (                                         -- 2. films that feature those actors
    SELECT DISTINCT "film_id"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR"
    WHERE "actor_id" IN (SELECT "actor_id" FROM top_actors)
),
inventory_top AS (                                     -- 3. inventory copies of those films
    SELECT DISTINCT "inventory_id"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY"
    WHERE "film_id" IN (SELECT "film_id" FROM films_top)
),
customers_top AS (                                     -- 4. customers who rented any copy
    SELECT DISTINCT "customer_id"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL"
    WHERE "inventory_id" IN (SELECT "inventory_id" FROM inventory_top)
),
counts AS (                                            -- 5. counts needed for percentage
    SELECT
        (SELECT COUNT(*) FROM customers_top)                                     AS "customers_top",
        (SELECT COUNT(*) FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."CUSTOMER")        AS "total_customers"
)
SELECT                                                  -- 6. final percentage (4-decimal precision)
    ROUND("customers_top" * 100.0 / "total_customers", 4) AS "percentage_customers"
FROM counts;