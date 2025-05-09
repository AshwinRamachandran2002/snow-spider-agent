WITH film_revenue AS (
    /* Total revenue earned by each film */
    SELECT
        i.film_id,
        SUM(p.amount) AS total_revenue
    FROM inventory AS i
    JOIN rental   AS r ON r.inventory_id = i.inventory_id
    JOIN payment  AS p ON p.rental_id    = r.rental_id
    GROUP BY i.film_id
),
actor_count AS (
    /* How many actors are in each film */
    SELECT
        film_id,
        COUNT(*) AS actor_count
    FROM film_actor
    GROUP BY film_id
),
actor_film_revenue AS (
    /* Revenue-per-actor for every actor–film pair */
    SELECT
        a.actor_id,
        a.first_name || ' ' || a.last_name       AS actor_name,
        f.film_id,
        f.title,
        ROUND(fr.total_revenue * 1.0 / ac.actor_count, 4) AS revenue_per_actor
    FROM actor       AS a
    JOIN film_actor  AS fa ON fa.actor_id = a.actor_id
    JOIN film        AS f  ON f.film_id   = fa.film_id
    JOIN film_revenue AS fr ON fr.film_id = f.film_id
    JOIN actor_count  AS ac ON ac.film_id = f.film_id
),
ranked AS (
    /* Rank films by revenue-per-actor within each actor’s filmography */
    SELECT
        actor_id,
        actor_name,
        film_id,
        title,
        revenue_per_actor,
        RANK() OVER (PARTITION BY actor_id
                     ORDER BY revenue_per_actor DESC) AS film_rank
    FROM actor_film_revenue
)
SELECT
    actor_id,
    actor_name,
    film_id,
    title,
    revenue_per_actor
FROM ranked
WHERE film_rank <= 3          -- top 3 films for each actor
ORDER BY actor_id, film_rank, film_id;