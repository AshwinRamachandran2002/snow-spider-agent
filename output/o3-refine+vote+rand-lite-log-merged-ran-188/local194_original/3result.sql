WITH film_rev AS (          -- total revenue per film
    SELECT  f.film_id,
            COALESCE(SUM(p.amount),0) AS film_revenue
    FROM    film        AS f
    LEFT JOIN inventory AS i ON i.film_id  = f.film_id
    LEFT JOIN rental    AS r ON r.inventory_id = i.inventory_id
    LEFT JOIN payment   AS p ON p.rental_id    = r.rental_id
    GROUP BY f.film_id
),
actor_cnt AS (              -- number of actors in each film
    SELECT  film_id,
            COUNT(actor_id) AS actor_cnt
    FROM    film_actor
    GROUP BY film_id
),
actor_film AS (             -- revenue share for every actor‑film pair
    SELECT  fa.actor_id,
            a.first_name,
            a.last_name,
            fa.film_id,
            f.title,
            fr.film_revenue,
            fr.film_revenue * 1.0 / ac.actor_cnt     AS revenue_per_actor,
            ROW_NUMBER() OVER (PARTITION BY fa.actor_id
                               ORDER BY fr.film_revenue DESC, fa.film_id) AS rn
    FROM        film_actor  AS fa
    JOIN        actor       AS a  ON a.actor_id = fa.actor_id
    JOIN        film        AS f  ON f.film_id  = fa.film_id
    JOIN        film_rev    AS fr ON fr.film_id = fa.film_id
    JOIN        actor_cnt   AS ac ON ac.film_id = fa.film_id
)
SELECT  actor_id,
        first_name,
        last_name,
        film_id,
        title            AS film_title,
        ROUND(film_revenue,4)         AS film_revenue,
        ROUND(revenue_per_actor,4)    AS average_revenue_per_actor
FROM    actor_film
WHERE   rn <= 3                          -- top 3 films per actor
ORDER BY actor_id, film_revenue DESC, film_id;