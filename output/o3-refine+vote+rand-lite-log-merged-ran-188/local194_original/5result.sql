WITH film_revenue AS (                     -- total revenue per film
    SELECT  i.film_id,
            SUM(p.amount) AS total_revenue
    FROM    payment  p
    JOIN    rental   r ON r.rental_id   = p.rental_id
    JOIN    inventory i ON i.inventory_id = r.inventory_id
    GROUP BY i.film_id
),
film_actor_cnt AS (                        -- number of actors in each film
    SELECT  film_id,
            COUNT(*) AS actor_cnt
    FROM    film_actor
    GROUP BY film_id
),
film_actor_rev AS (                        -- revenue share per actor‑film
    SELECT  fa.actor_id,
            fa.film_id,
            (fr.total_revenue * 1.0) / fac.actor_cnt AS actor_revenue
    FROM    film_actor      fa
    JOIN    film_revenue    fr  ON fr.film_id  = fa.film_id
    JOIN    film_actor_cnt  fac ON fac.film_id = fa.film_id
),
ranked AS (                                -- rank films by revenue share per actor
    SELECT  far.actor_id,
            far.film_id,
            far.actor_revenue,
            ROW_NUMBER() OVER (
                PARTITION BY far.actor_id
                ORDER BY     far.actor_revenue DESC, far.film_id
            ) AS rn
    FROM    film_actor_rev far
)
SELECT  a.actor_id,
        a.first_name,
        a.last_name,
        f.film_id,
        f.title,
        ROUND(r.actor_revenue,4) AS actor_revenue_per_film
FROM    ranked         r
JOIN    actor          a ON a.actor_id = r.actor_id
JOIN    film           f ON f.film_id  = r.film_id
WHERE   r.rn <= 3                          -- top 3 films per actor
ORDER BY a.actor_id,
         r.actor_revenue DESC,
         f.film_id;