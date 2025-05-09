WITH filtered_films AS (
    SELECT f."film_id"
    FROM PAGILA.PAGILA.FILM              f
    JOIN PAGILA.PAGILA.LANGUAGE          l  ON f."language_id" = l."language_id"
    JOIN PAGILA.PAGILA.FILM_CATEGORY     fc ON f."film_id"     = fc."film_id"
    JOIN PAGILA.PAGILA.CATEGORY          c  ON fc."category_id"= c."category_id"
    WHERE l."name"           = 'English'
      AND c."name"           = 'Children'
      AND f."rating"         IN ('G','PG')
      AND f."length"         <= 120
      AND TO_NUMBER(f."release_year") BETWEEN 2000 AND 2010
),
actor_counts AS (
    SELECT a."actor_id",
           a."first_name",
           a."last_name",
           COUNT(*) AS film_count
    FROM PAGILA.PAGILA.FILM_ACTOR fa
    JOIN filtered_films          ff ON fa."film_id" = ff."film_id"
    JOIN PAGILA.PAGILA.ACTOR     a  ON fa."actor_id" = a."actor_id"
    GROUP BY a."actor_id", a."first_name", a."last_name"
)
SELECT ("first_name" || ' ' || "last_name") AS actor_full_name
FROM (
    SELECT actor_counts.*,
           ROW_NUMBER() OVER (ORDER BY film_count DESC) AS rn
    FROM actor_counts
)
WHERE rn = 1;