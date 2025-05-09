WITH actor_rentals AS (                  -- rentals per actor
    SELECT
        fa."actor_id",
        COUNT(r."rental_id") AS "rental_cnt"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.FILM_ACTOR   fa
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.INVENTORY    i  ON i."film_id"     = fa."film_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.RENTAL       r  ON r."inventory_id" = i."inventory_id"
    GROUP BY fa."actor_id"
),
top5_actors AS (                          -- five most-rented actors
    SELECT "actor_id"
    FROM actor_rentals
    ORDER BY "rental_cnt" DESC NULLS LAST
    LIMIT 5
),
top5_customers AS (                       -- customers who rented films with those actors
    SELECT DISTINCT
        r."customer_id"
    FROM top5_actors                       t
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.FILM_ACTOR fa ON fa."actor_id" = t."actor_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.INVENTORY  i  ON i."film_id"   = fa."film_id"
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.RENTAL     r  ON r."inventory_id" = i."inventory_id"
),
all_customers AS (                        -- every customer who ever rented
    SELECT DISTINCT "customer_id"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.RENTAL
)
SELECT
    ROUND(
        (SELECT COUNT(*) FROM top5_customers) * 100.0
        / NULLIF((SELECT COUNT(*) FROM all_customers), 0),
        4
    ) AS "pct_customers_top5_actors";