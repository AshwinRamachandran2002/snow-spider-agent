WITH top5_actors AS (
    /* 1.  Identify the five actors whose films have been rented the most. */
    SELECT fa.actor_id
    FROM film_actor  AS fa
    JOIN inventory   AS i ON i.film_id      = fa.film_id
    JOIN rental      AS r ON r.inventory_id = i.inventory_id
    GROUP BY fa.actor_id
    ORDER BY COUNT(r.rental_id) DESC
    LIMIT 5
),
customers_who_rented_top5 AS (
    /* 2.  Find every distinct customer who rented at least one film featuring any of those actors. */
    SELECT DISTINCT r.customer_id
    FROM rental      AS r
    JOIN inventory   AS i  ON i.inventory_id = r.inventory_id
    JOIN film_actor  AS fa ON fa.film_id     = i.film_id
    WHERE fa.actor_id IN (SELECT actor_id FROM top5_actors)
)
/* 3.  Calculate the percentage of all customers represented by that group. */
SELECT
    ROUND(
        100.0 * (SELECT COUNT(*) FROM customers_who_rented_top5)
        /       (SELECT COUNT(*) FROM customer),
        4
    ) AS percentage_of_customers_renting_top5_actor_films;