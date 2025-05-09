WITH top5 AS (
    SELECT fa.actor_id
    FROM film_actor AS fa
    JOIN inventory  AS i ON i.film_id      = fa.film_id
    JOIN rental     AS r ON r.inventory_id = i.inventory_id
    GROUP BY fa.actor_id
    ORDER BY COUNT(*) DESC, fa.actor_id
    LIMIT 5
),
cust_top5 AS (
    SELECT DISTINCT r.customer_id
    FROM top5       AS t
    JOIN film_actor AS fa ON fa.actor_id  = t.actor_id
    JOIN inventory  AS i  ON i.film_id    = fa.film_id
    JOIN rental     AS r  ON r.inventory_id = i.inventory_id
),
tot AS (
    SELECT COUNT(DISTINCT customer_id) AS total_customers
    FROM customer
)
SELECT
    ROUND(
        (SELECT COUNT(*) FROM cust_top5) * 100.0 /
        (SELECT total_customers FROM tot), 4
    ) AS percentage_of_customers;