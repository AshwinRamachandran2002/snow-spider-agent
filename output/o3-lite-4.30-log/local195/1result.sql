WITH films_per_actor AS (
    SELECT actor_id,
           COUNT(*) AS film_cnt
    FROM film_actor
    GROUP BY actor_id
),
top5_actors AS (
    SELECT actor_id
    FROM films_per_actor
    ORDER BY film_cnt DESC, actor_id
    LIMIT 5
),
top5_films AS (
    SELECT DISTINCT film_id
    FROM film_actor
    WHERE actor_id IN (SELECT actor_id FROM top5_actors)
),
top5_inventory AS (
    SELECT inventory_id
    FROM inventory
    WHERE film_id IN (SELECT film_id FROM top5_films)
),
customers_top5 AS (
    SELECT DISTINCT customer_id
    FROM rental
    WHERE inventory_id IN (SELECT inventory_id FROM top5_inventory)
),
counts AS (
    SELECT 
        (SELECT COUNT(*) FROM customers_top5) AS top5_customers,
        (SELECT COUNT(*) FROM customer)       AS total_customers
)
SELECT ROUND(100.0 * top5_customers / total_customers, 4) AS percentage_of_customers
FROM counts;