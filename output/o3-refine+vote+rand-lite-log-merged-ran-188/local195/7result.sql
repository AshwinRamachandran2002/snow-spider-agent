WITH actor_rental_counts AS (
    SELECT
        fa.actor_id,
        COUNT(*) AS rental_cnt
    FROM rental r
    JOIN inventory      i  ON i.inventory_id = r.inventory_id
    JOIN film           f  ON f.film_id      = i.film_id
    JOIN film_actor     fa ON fa.film_id     = f.film_id
    GROUP BY fa.actor_id
),
top_five_actors AS (
    SELECT actor_id
    FROM actor_rental_counts
    ORDER BY rental_cnt DESC, actor_id
    LIMIT 5
),
customers_renting_top5 AS (
    SELECT DISTINCT r.customer_id
    FROM rental r
    JOIN inventory  i  ON i.inventory_id = r.inventory_id
    JOIN film       f  ON f.film_id      = i.film_id
    JOIN film_actor fa ON fa.film_id     = f.film_id
    WHERE fa.actor_id IN (SELECT actor_id FROM top_five_actors)
),
totals AS (
    SELECT (SELECT COUNT(*) FROM customer)          AS total_customers,
           (SELECT COUNT(*) FROM customers_renting_top5) AS top5_customers
)
SELECT
    ROUND(top5_customers * 100.0 / total_customers, 4) AS percent_of_customers
FROM totals;