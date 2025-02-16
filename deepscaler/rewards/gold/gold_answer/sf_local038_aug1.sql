-- Task: Could you provide me with the full names of actors who starred in children's category films released between 2000 and 2010? Please limit the results to the first 100 entries.

SELECT
    ACTOR."first_name" || ' ' || ACTOR."last_name" AS "full_name"
FROM
    PAGILA.PAGILA.ACTOR
INNER JOIN PAGILA.PAGILA.FILM_ACTOR ON ACTOR."actor_id" = FILM_ACTOR."actor_id"
INNER JOIN PAGILA.PAGILA.FILM ON FILM_ACTOR."film_id" = FILM."film_id"
INNER JOIN PAGILA.PAGILA.FILM_CATEGORY ON FILM."film_id" = FILM_CATEGORY."film_id"
INNER JOIN PAGILA.PAGILA.CATEGORY ON FILM_CATEGORY."category_id" = CATEGORY."category_id"
WHERE
    CATEGORY."name" = 'Children' AND
    FILM."release_year" BETWEEN 2000 AND 2010
GROUP BY
    ACTOR."actor_id", ACTOR."first_name", ACTOR."last_name"
LIMIT 100;