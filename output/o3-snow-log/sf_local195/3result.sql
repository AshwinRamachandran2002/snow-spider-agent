WITH top5_actors AS (      -- 1) find the five most-featured actors
    SELECT "actor_id"
    FROM   "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR"
    GROUP  BY "actor_id"
    ORDER  BY COUNT("film_id") DESC NULLS LAST
    LIMIT  5
),
customers_with_top5 AS (   -- 2) customers who rented at least one film with any top-five actor
    SELECT DISTINCT r."customer_id"
    FROM   "SQLITE_SAKILA"."SQLITE_SAKILA"."RENTAL"       r
    JOIN   "SQLITE_SAKILA"."SQLITE_SAKILA"."INVENTORY"    i  ON r."inventory_id" = i."inventory_id"
    JOIN   "SQLITE_SAKILA"."SQLITE_SAKILA"."FILM_ACTOR"   fa ON i."film_id"      = fa."film_id"
    WHERE  fa."actor_id" IN (SELECT "actor_id" FROM top5_actors)
),
all_customers AS (         -- 3) every customer on file
    SELECT DISTINCT "customer_id"
    FROM   "SQLITE_SAKILA"."SQLITE_SAKILA"."CUSTOMER"
)

-- 4) percentage of customers who have rented films featuring the top-five actors
SELECT 
    ROUND( 
        (SELECT COUNT(*) FROM customers_with_top5)::FLOAT
        / NULLIF((SELECT COUNT(*) FROM all_customers), 0) 
        * 100
    , 4) AS "percent_customers_top5_actors";