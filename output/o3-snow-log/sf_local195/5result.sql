WITH top5_actors AS (          -- 1) Five most-rented actors
    SELECT 
        fa."actor_id",
        COUNT(r."rental_id") AS rentals_cnt
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR"  fa
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY"   i ON fa."film_id"      = i."film_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL"      r ON i."inventory_id"  = r."inventory_id"
    GROUP BY fa."actor_id"
    ORDER BY rentals_cnt DESC NULLS LAST
    LIMIT 5
),
customers_top5 AS (            -- 2) Customers who rented at least one film with any top-5 actor
    SELECT DISTINCT
        r."customer_id"
    FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR"  fa
    JOIN top5_actors                                t ON fa."actor_id"      = t."actor_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY"   i ON fa."film_id"      = i."film_id"
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL"      r ON i."inventory_id"  = r."inventory_id"
),
counts AS (                   -- 3) Gather counts needed for the percentage
    SELECT
        (SELECT COUNT(*)                           FROM customers_top5)               AS cust_top5_cnt,
        (SELECT COUNT(DISTINCT "customer_id") 
           FROM "SQLITE_SAKILA"."SQLITE_SAKILA"."CUSTOMER")                          AS total_cust_cnt
)
-- 4) Final percentage of customers who rented films featuring the top-5 actors
SELECT 
    ROUND(cust_top5_cnt * 100.0 / total_cust_cnt, 4) AS "pct_customers_top5"
FROM counts;