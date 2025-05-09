/* Percentage of customers that have rented at least one film featuring the five most-rented actors */
WITH top_actors AS (   -- 1) find the 5 actors whose films were rented the most
    SELECT fa."actor_id"
    FROM   SQLITE_SAKILA.SQLITE_SAKILA."FILM_ACTOR"  fa
    JOIN   SQLITE_SAKILA.SQLITE_SAKILA."INVENTORY"   i  ON fa."film_id" = i."film_id"
    JOIN   SQLITE_SAKILA.SQLITE_SAKILA."RENTAL"      r  ON i."inventory_id" = r."inventory_id"
    GROUP  BY fa."actor_id"
    ORDER  BY COUNT(r."rental_id") DESC NULLS LAST
    LIMIT  5
),
customers_top AS (     -- 2) customers who rented any film with those actors
    SELECT DISTINCT r."customer_id"
    FROM   SQLITE_SAKILA.SQLITE_SAKILA."RENTAL"      r
    JOIN   SQLITE_SAKILA.SQLITE_SAKILA."INVENTORY"   i  ON r."inventory_id" = i."inventory_id"
    JOIN   SQLITE_SAKILA.SQLITE_SAKILA."FILM_ACTOR"  fa ON i."film_id"      = fa."film_id"
    WHERE  fa."actor_id" IN (SELECT "actor_id" FROM top_actors)
),
counts AS (            -- 3) bring both totals together
    SELECT
        (SELECT COUNT(*)                                   FROM customers_top)                                    AS customers_with_top5,
        (SELECT COUNT(DISTINCT "customer_id")
         FROM   SQLITE_SAKILA.SQLITE_SAKILA."CUSTOMER")   AS total_customers
)
SELECT
    customers_with_top5,
    total_customers,
    ROUND(customers_with_top5 * 100.0 / total_customers, 4) AS percentage_of_customers
FROM counts;