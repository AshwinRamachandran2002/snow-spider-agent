WITH actor_rentals AS (
    SELECT
        fa.actor_id,
        COUNT(*) AS rental_cnt
    FROM film_actor fa
    JOIN inventory i  ON i.film_id = fa.film_id
    JOIN rental    r  ON r.inventory_id = i.inventory_id
    GROUP BY fa.actor_id
),
top_five AS (
    SELECT actor_id
    FROM actor_rentals
    ORDER BY rental_cnt DESC, actor_id
    LIMIT 5
),
customers_top_actors AS (
    SELECT DISTINCT r.customer_id
    FROM top_five t
    JOIN film_actor fa ON fa.actor_id = t.actor_id
    JOIN inventory  i  ON i.film_id = fa.film_id
    JOIN rental     r  ON r.inventory_id = i.inventory_id
)
SELECT
    100.0 * (SELECT COUNT(*) FROM customers_top_actors)
          / (SELECT COUNT(*) FROM customer)  AS percentage_of_customers
;