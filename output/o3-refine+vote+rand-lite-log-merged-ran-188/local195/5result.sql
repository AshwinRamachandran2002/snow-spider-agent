WITH actor_rentals AS (
    SELECT
        fa.actor_id,
        COUNT(r.rental_id) AS rental_cnt
    FROM film_actor fa
    JOIN inventory  i ON i.film_id      = fa.film_id
    JOIN rental     r ON r.inventory_id = i.inventory_id
    GROUP BY fa.actor_id
),
top_five_actors AS (
    SELECT actor_id
    FROM actor_rentals
    ORDER BY rental_cnt DESC, actor_id
    LIMIT 5
),
customers_who_rented_top AS (
    SELECT DISTINCT r.customer_id
    FROM rental r
    JOIN inventory  i  ON i.inventory_id = r.inventory_id
    JOIN film_actor fa ON fa.film_id     = i.film_id
    WHERE fa.actor_id IN (SELECT actor_id FROM top_five_actors)
),
totals AS (
    SELECT
        (SELECT COUNT(*)                FROM customers_who_rented_top)     AS top_actor_customers,
        (SELECT COUNT(DISTINCT customer_id) FROM customer)                 AS all_customers
)
SELECT
    ROUND(CAST(top_actor_customers AS FLOAT) * 100.0 / all_customers, 4) 
        AS percentage_of_customers_who_rented_top_five_actors
FROM totals;