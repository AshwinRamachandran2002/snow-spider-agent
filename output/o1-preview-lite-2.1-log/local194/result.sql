WITH total_revenue_per_film AS (
    SELECT
        f.film_id,
        f.title AS film_title,
        SUM(p.amount) AS total_revenue
    FROM
        film f
        JOIN inventory i ON f.film_id = i.film_id
        JOIN rental r ON i.inventory_id = r.inventory_id
        JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY
        f.film_id
),
num_actors_per_film AS (
    SELECT
        fa.film_id,
        COUNT(DISTINCT fa.actor_id) AS num_actors
    FROM
        film_actor fa
    GROUP BY
        fa.film_id
),
average_revenue_per_film AS (
    SELECT
        tr.film_id,
        tr.film_title,
        tr.total_revenue,
        na.num_actors,
        tr.total_revenue / na.num_actors AS average_revenue_per_actor
    FROM
        total_revenue_per_film tr
        JOIN num_actors_per_film na ON tr.film_id = na.film_id
),
actor_film_revenue AS (
    SELECT
        a.actor_id,
        a.first_name || ' ' || a.last_name AS actor_name,
        ar.film_title,
        ar.average_revenue_per_actor
    FROM
        actor a
        JOIN film_actor fa ON a.actor_id = fa.actor_id
        JOIN average_revenue_per_film ar ON fa.film_id = ar.film_id
),
ranked_films AS (
    SELECT
        afr.actor_name,
        afr.film_title,
        afr.average_revenue_per_actor,
        ROW_NUMBER() OVER (
            PARTITION BY afr.actor_name
            ORDER BY afr.average_revenue_per_actor DESC
        ) AS rank
    FROM
        actor_film_revenue afr
)
SELECT
    actor_name,
    film_title,
    ROUND(average_revenue_per_actor, 4) AS average_revenue_per_actor
FROM
    ranked_films
WHERE
    rank <= 3
ORDER BY
    actor_name,
    average_revenue_per_actor DESC;