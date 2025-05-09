WITH actor_rentals AS (
    -- total rentals per actor
    SELECT fa.actor_id,
           COUNT(*) AS rental_cnt
    FROM film_actor  AS fa
    JOIN inventory   AS i USING (film_id)
    JOIN rental      AS r USING (inventory_id)
    GROUP BY fa.actor_id
),
top_actors AS (
    -- five actors whose films have been rented the most
    SELECT actor_id
    FROM actor_rentals
    ORDER BY rental_cnt DESC, actor_id
    LIMIT 5
),
customers_with_top AS (
    -- distinct customers who have rented at least one film
    -- featuring any of those five actors
    SELECT DISTINCT r.customer_id
    FROM top_actors  AS ta
    JOIN film_actor  AS fa ON fa.actor_id = ta.actor_id
    JOIN inventory   AS i  USING (film_id)
    JOIN rental      AS r  USING (inventory_id)
)
SELECT
    ROUND(
        (SELECT COUNT(*) FROM customers_with_top) * 100.0
        / (SELECT COUNT(*) FROM customer),
        4
    ) AS percentage_of_customers;