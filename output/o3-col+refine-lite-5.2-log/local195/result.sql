WITH top5 AS (
    /* 1. Find the five actors whose films were rented the most */
    SELECT fa.actor_id
    FROM film_actor AS fa
    JOIN inventory  AS i ON i.film_id      = fa.film_id
    JOIN rental     AS r ON r.inventory_id = i.inventory_id
    GROUP BY fa.actor_id
    ORDER BY COUNT(*) DESC, fa.actor_id
    LIMIT 5
),
customers_top5 AS (
    /* 2. All customers who have rented at least one film featuring any of those top‑5 actors */
    SELECT DISTINCT r.customer_id
    FROM rental     AS r
    JOIN inventory  AS i  ON i.inventory_id = r.inventory_id
    JOIN film_actor AS fa ON fa.film_id     = i.film_id
    WHERE fa.actor_id IN (SELECT actor_id FROM top5)
)
SELECT
    (SELECT COUNT(*) FROM customers_top5)           AS customers_top5,
    (SELECT COUNT(*) FROM customer)                 AS total_customers,
    ROUND(100.0 * (SELECT COUNT(*) FROM customers_top5) /
                 (SELECT COUNT(*) FROM customer), 2) AS percentage_top5_customers;