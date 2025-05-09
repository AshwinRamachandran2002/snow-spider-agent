WITH film_revenue AS (           -- 1. revenue earned by each film
    SELECT  i.film_id,
            SUM(p.amount) AS total_revenue
    FROM    payment  p
    JOIN    rental   r ON r.rental_id   = p.rental_id
    JOIN    inventory i ON i.inventory_id = r.inventory_id
    GROUP BY i.film_id
),
actor_count AS (                 -- 2. number of actors per film
    SELECT  film_id,
            COUNT(*) AS num_actors
    FROM    film_actor
    GROUP BY film_id
),
actor_film_revenue AS (          -- 3. revenue share for every actor‑film pair
    SELECT  fa.actor_id,
            fa.film_id,
            COALESCE(fr.total_revenue,0) / ac.num_actors AS revenue_per_actor
    FROM    film_actor  fa
    LEFT JOIN film_revenue fr ON fr.film_id = fa.film_id
    JOIN     actor_count ac ON ac.film_id  = fa.film_id
),
ranked AS (                      -- 4. rank films by revenue share for each actor
    SELECT  afr.*,
            ROW_NUMBER() OVER (PARTITION BY afr.actor_id
                               ORDER BY afr.revenue_per_actor DESC, afr.film_id) AS rn
    FROM    actor_film_revenue afr
)
SELECT  a.actor_id,
        a.first_name,
        a.last_name,
        f.film_id,
        f.title,
        ROUND(r.revenue_per_actor,4) AS revenue_per_actor     -- 5. top‑3 films per actor
FROM    ranked           r
JOIN    actor            a ON a.actor_id = r.actor_id
JOIN    film             f ON f.film_id  = r.film_id
WHERE   r.rn <= 3
ORDER BY a.actor_id,
         r.revenue_per_actor DESC,
         f.film_id;