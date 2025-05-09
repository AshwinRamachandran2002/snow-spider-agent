WITH film_revenue AS (   -- 1. total revenue per film
    SELECT  i.film_id,
            SUM(p.amount) AS total_revenue
    FROM    payment  p
    JOIN    rental   r ON r.rental_id   = p.rental_id
    JOIN    inventory i ON i.inventory_id = r.inventory_id
    GROUP BY i.film_id
),
actor_count AS (        -- 2. number of actors in every film
    SELECT  film_id,
            COUNT(*) AS actor_cnt
    FROM    film_actor
    GROUP BY film_id
),
film_rev_per_actor AS ( -- 3. revenue share each actor gets for a film
    SELECT  fr.film_id,
            fr.total_revenue,
            ac.actor_cnt,
            fr.total_revenue * 1.0 / ac.actor_cnt AS revenue_per_actor
    FROM    film_revenue fr
    JOIN    actor_count  ac ON ac.film_id = fr.film_id
),
actor_film_rev AS (     -- 4. attach actors & films to their revenue share
    SELECT  fa.actor_id,
            a.first_name,
            a.last_name,
            fa.film_id,
            f.title,
            fp.revenue_per_actor
    FROM    film_actor          fa
    JOIN    actor               a  ON a.actor_id = fa.actor_id
    JOIN    film                f  ON f.film_id  = fa.film_id
    JOIN    film_rev_per_actor  fp ON fp.film_id = fa.film_id
),
ranked AS (              -- 5. rank films by revenue share for each actor
    SELECT  *,
            ROW_NUMBER() OVER (
                PARTITION BY actor_id
                ORDER BY revenue_per_actor DESC, film_id
            ) AS rn
    FROM    actor_film_rev
)
-- 6. pick top‑3 films for every actor
SELECT  actor_id,
        first_name,
        last_name,
        film_id,
        title        AS film_title,
        ROUND(revenue_per_actor, 4) AS revenue_per_actor
FROM    ranked
WHERE   rn <= 3
ORDER BY actor_id, revenue_per_actor DESC, film_id;