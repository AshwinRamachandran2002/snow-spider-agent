WITH top5_actors AS (        -- 1. five actors with the highest rental volume
    SELECT fa.actor_id
    FROM film_actor  AS fa
    JOIN inventory   AS i  ON i.film_id      = fa.film_id
    JOIN rental      AS r  ON r.inventory_id = i.inventory_id
    GROUP BY fa.actor_id
    ORDER BY COUNT(r.rental_id) DESC
    LIMIT 5
),
customers_top5 AS (          -- 2. customers who rented at least one film of those actors
    SELECT DISTINCT r.customer_id
    FROM   rental      AS r
    JOIN   inventory   AS i  ON i.inventory_id = r.inventory_id
    JOIN   film_actor  AS fa ON fa.film_id     = i.film_id
    WHERE  fa.actor_id IN (SELECT actor_id FROM top5_actors)
),
total_customers AS (         -- 3. total customers in the DB
    SELECT COUNT(DISTINCT customer_id) AS cnt
    FROM   customer
)
SELECT
    ROUND(
        100.0 * (SELECT COUNT(*) FROM customers_top5)
               / (SELECT cnt FROM total_customers),
        4
    ) AS percentage_of_customers;   -- 4. final percentage (4-decimal precision)