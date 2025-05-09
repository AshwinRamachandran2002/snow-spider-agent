WITH film_revenue AS (                 -- total revenue per film
    SELECT i.film_id,
           SUM(p.amount) AS film_revenue
    FROM payment  p
    JOIN rental   r ON p.rental_id   = r.rental_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    GROUP BY i.film_id
),
cast_size AS (                         -- number of actors in each film
    SELECT film_id,
           COUNT(*) AS actor_cnt
    FROM film_actor
    GROUP BY film_id
),
actor_film_money AS (                  -- revenue share for each actor‑film pair
    SELECT fa.actor_id,
           fa.film_id,
           fr.film_revenue,
           fr.film_revenue * 1.0 / cs.actor_cnt AS revenue_per_actor
    FROM film_actor  fa
    JOIN film_revenue fr ON fa.film_id = fr.film_id
    JOIN cast_size    cs ON fa.film_id = cs.film_id
),
ranked AS (                            -- actor’s top 3 films by total revenue
    SELECT af.*,
           ROW_NUMBER() OVER (
               PARTITION BY actor_id
               ORDER BY film_revenue DESC, film_id
           ) AS rn
    FROM actor_film_money af
)
SELECT
    a.first_name || ' ' || a.last_name AS actor_name,
    f.title                            AS film_title,
    ROUND(r.film_revenue, 4)           AS total_film_revenue,
    ROUND(r.revenue_per_actor, 4)      AS avg_revenue_per_actor
FROM ranked r
JOIN actor a ON r.actor_id = a.actor_id
JOIN film  f ON r.film_id  = f.film_id
WHERE r.rn <= 3
ORDER BY a.actor_id, r.film_revenue DESC, f.film_id;