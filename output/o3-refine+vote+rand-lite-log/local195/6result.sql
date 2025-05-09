WITH top_actors AS (
    SELECT fa.actor_id,
           COUNT(DISTINCT fa.film_id) AS film_total
    FROM film_actor fa
    GROUP BY fa.actor_id
    ORDER BY film_total DESC, fa.actor_id
    LIMIT 5
),
films_of_top AS (
    SELECT DISTINCT fa.film_id
    FROM film_actor fa
    JOIN top_actors ta ON ta.actor_id = fa.actor_id
),
customers_with_top AS (
    SELECT DISTINCT r.customer_id
    FROM rental   r
    JOIN inventory i ON i.inventory_id = r.inventory_id
    WHERE i.film_id IN (SELECT film_id FROM films_of_top)
)
SELECT ROUND(
         (SELECT COUNT(*) FROM customers_with_top) * 100.0
         / (SELECT COUNT(*) FROM customer),
         4
       ) AS percentage_of_customers_who_rented_top5_actors_films;