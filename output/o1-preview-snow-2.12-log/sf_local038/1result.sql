SELECT CONCAT(A."first_name", ' ', A."last_name") AS "name"
FROM PAGILA.PAGILA.ACTOR A
JOIN PAGILA.PAGILA.FILM_ACTOR FA ON A."actor_id" = FA."actor_id"
JOIN (
    SELECT F."film_id"
    FROM PAGILA.PAGILA.FILM F
    JOIN PAGILA.PAGILA.FILM_CATEGORY FC ON F."film_id" = FC."film_id"
    WHERE
        F."language_id" = (
            SELECT "language_id"
            FROM PAGILA.PAGILA.LANGUAGE
            WHERE "name" = 'English'
        )
        AND F."rating" IN ('G', 'PG')
        AND F."length" <= 120
        AND F."release_year" BETWEEN '2000' AND '2010'
        AND FC."category_id" = (
            SELECT "category_id"
            FROM PAGILA.PAGILA.CATEGORY
            WHERE "name" = 'Children'
        )
) AS MatchingFilms ON FA."film_id" = MatchingFilms."film_id"
GROUP BY A."actor_id", A."first_name", A."last_name"
ORDER BY COUNT(*) DESC NULLS LAST
LIMIT 1;