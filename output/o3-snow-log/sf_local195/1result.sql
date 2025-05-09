WITH top5_actors AS (   -- 1) pick the five actors whose films generate the most rentals
    SELECT
        fa."actor_id"
    FROM SQLITE_SAKILA.SQLITE_SAKILA."FILM_ACTOR"  fa
    JOIN SQLITE_SAKILA.SQLITE_SAKILA."INVENTORY"   i  ON i."film_id"      = fa."film_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA."RENTAL"      r  ON r."inventory_id" = i."inventory_id"
    GROUP BY fa."actor_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 5
),
customers_top5 AS (     -- 2) every customer who has rented at least one film with any of those actors
    SELECT DISTINCT
        r."customer_id"
    FROM SQLITE_SAKILA.SQLITE_SAKILA."RENTAL"      r
    JOIN SQLITE_SAKILA.SQLITE_SAKILA."INVENTORY"   i  ON i."inventory_id" = r."inventory_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA."FILM_ACTOR"  fa ON fa."film_id"     = i."film_id"
    WHERE fa."actor_id" IN (SELECT "actor_id" FROM top5_actors)
),
totals AS (             -- 3) total number of customers in the database
    SELECT COUNT(*) AS "total_customers"
    FROM   SQLITE_SAKILA.SQLITE_SAKILA."CUSTOMER"
)
-- 4) final answer: how widespread is the appeal of those five actors?
SELECT
    (SELECT COUNT(*) FROM customers_top5)                                       AS "customers_top5_actors",
    (SELECT "total_customers" FROM totals)                                      AS "total_customers",
    ROUND((SELECT COUNT(*) FROM customers_top5) * 100.0 /
          (SELECT "total_customers" FROM totals), 4)                            AS "percentage_customers_top5_actors";