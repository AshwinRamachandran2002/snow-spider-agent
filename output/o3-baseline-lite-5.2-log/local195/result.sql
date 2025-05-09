WITH top5_actors AS (
    /* 1. Find the five actors whose films generated the most rentals */
    SELECT fa.actor_id
    FROM film_actor AS fa
    JOIN inventory  AS i ON i.film_id     = fa.film_id
    JOIN rental     AS r ON r.inventory_id = i.inventory_id
    GROUP BY fa.actor_id
    ORDER BY COUNT(*) DESC, fa.actor_id
    LIMIT 5
),
customers_with_top5 AS (
    /* 2. All customers who rented a film featuring any of those actors */
    SELECT DISTINCT r.customer_id
    FROM rental      AS r
    JOIN inventory   AS i  ON i.inventory_id = r.inventory_id
    JOIN film_actor  AS fa ON fa.film_id     = i.film_id
    WHERE fa.actor_id IN (SELECT actor_id FROM top5_actors)
)
SELECT
    ROUND(
        CAST((SELECT COUNT(*) FROM customers_with_top5) AS REAL)
        * 100.0
        / (SELECT COUNT(*) FROM customer),
        4
    ) AS percentage_of_customers_with_top_five_actor_rentals;