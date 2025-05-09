WITH rentals_per_actor AS (
    SELECT fa.actor_id,
           COUNT(r.rental_id) AS rental_cnt
    FROM film_actor fa
    JOIN inventory  i ON i.film_id     = fa.film_id
    JOIN rental     r ON r.inventory_id = i.inventory_id
    GROUP BY fa.actor_id
),
top5 AS (
    SELECT actor_id
    FROM rentals_per_actor
    ORDER BY rental_cnt DESC, actor_id
    LIMIT 5
),
customers_with_top5 AS (
    SELECT DISTINCT r.customer_id
    FROM top5 t
    JOIN film_actor fa ON fa.actor_id = t.actor_id
    JOIN inventory  i  ON i.film_id   = fa.film_id
    JOIN rental     r  ON r.inventory_id = i.inventory_id
)
SELECT ROUND(
           (SELECT COUNT(*) FROM customers_with_top5) * 100.0 /
           (SELECT COUNT(*) FROM customer),
       4) AS percentage_of_customers;