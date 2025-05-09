WITH film_revenue AS (          -- total revenue per film
    SELECT  i.film_id,
            SUM(p.amount) AS film_rev
    FROM    payment   p
    JOIN    rental    r ON r.rental_id   = p.rental_id
    JOIN    inventory i ON i.inventory_id = r.inventory_id
    GROUP BY i.film_id
),
actor_cnt AS (                  -- number of actors in each film
    SELECT  fa.film_id,
            COUNT(DISTINCT fa.actor_id) AS cnt
    FROM    film_actor fa
    GROUP BY fa.film_id
),
actor_film AS (                 -- revenue share for every actor-film pair
    SELECT  fa.actor_id,
            fa.film_id,
            fr.film_rev / ac.cnt AS revenue_share
    FROM    film_actor  fa
    JOIN    film_revenue fr ON fr.film_id = fa.film_id
    JOIN    actor_cnt    ac ON ac.film_id = fa.film_id
),
ranked AS (                      -- rank films by revenue share per actor
    SELECT  *,
            ROW_NUMBER() OVER (PARTITION BY actor_id
                               ORDER BY revenue_share DESC) AS rn
    FROM    actor_film
),
avg_top3 AS (                    -- average of the top-3 shares per actor
    SELECT  actor_id,
            AVG(revenue_share) AS avg_rev
    FROM    ranked
    WHERE   rn <= 3
    GROUP BY actor_id
)
SELECT  a.actor_id,
        a.first_name,
        a.last_name,
        f.title,
        ROUND(r.revenue_share, 4)  AS revenue_share,
        ROUND(at.avg_rev,     4)  AS avg_top3_revenue
FROM    ranked   r
JOIN    actor    a  ON a.actor_id = r.actor_id
JOIN    film     f  ON f.film_id  = r.film_id
JOIN    avg_top3 at ON at.actor_id = r.actor_id
WHERE   r.rn <= 3                     -- keep only the top 3 films
ORDER BY a.actor_id, r.rn;