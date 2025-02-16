-- Task: Could you provide up to 100 titles of English-language children's films released between 2000 and 2010?
SELECT film.title
FROM film
INNER JOIN film_category ON film.film_id = film_category.film_id
INNER JOIN category ON film_category.category_id = category.category_id
-- Join with the language table
INNER JOIN language ON film.language_id = language.language_id
WHERE
    category.name = 'Children' AND
    film.release_year BETWEEN 2000 AND 2010 AND
    language.name = 'English'
LIMIT 100;