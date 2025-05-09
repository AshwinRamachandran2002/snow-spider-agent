WITH film_revenue AS (           -- total revenue per film
    SELECT 
        i.film_id,
        SUM(p.amount) AS film_rev
    FROM payment       p
    JOIN rental        r  ON r.rental_id   = p.rental_id
    JOIN inventory     i  ON i.inventory_id = r.inventory_id
    GROUP BY i.film_id
),
film_actor_cnt AS (             -- number of actors in every film
    SELECT 
        film_id,
        COUNT(*) AS actor_cnt
    FROM film_actor
    GROUP BY film_id
),
actor_film_share AS (           -- each actor’s revenue share in every film
    SELECT 
        fa.actor_id,
        fa.film_id,
        COALESCE(fr.film_rev,0) / fac.actor_cnt AS actor_share
    FROM film_actor      fa
    LEFT JOIN film_revenue   fr   ON fr.film_id = fa.film_id
    JOIN film_actor_cnt  fac  ON fac.film_id = fa.film_id
),
ranked AS (                     -- rank films (by share) for every actor
    SELECT
        actor_id,
        film_id,
        actor_share,
        ROW_NUMBER() OVER (
            PARTITION BY actor_id 
            ORDER BY actor_share DESC, film_id
        ) AS rn
    FROM actor_film_share
),
top3 AS (                       -- keep only top‑3 films per actor
    SELECT * 
    FROM ranked
    WHERE rn <= 3
),
avg_top3 AS (                   -- average share across those top‑3 films
    SELECT 
        actor_id,
        AVG(actor_share) AS avg_share
    FROM top3
    GROUP BY actor_id
)
SELECT 
    a.actor_id,
    a.first_name,
    a.last_name,
    f.film_id,
    f.title,
    ROUND(t.actor_share,4)      AS actor_share_revenue,
    ROUND(at.avg_share,4)       AS avg_top3_revenue
FROM top3          t
JOIN actor         a  ON a.actor_id = t.actor_id
JOIN film          f  ON f.film_id  = t.film_id
JOIN avg_top3      at ON at.actor_id = t.actor_id
ORDER BY 
    a.actor_id,
    t.actor_share DESC,
    f.film_id;