-- Task: Find the name of the film category that has the highest total rental hours among all categories, where total rental hours are calculated by summing the rental durations (in hours) of films rented in cities whose names either start with 'A' (case-insensitive) or contain a hyphen. Return only the name of this category.
SELECT
    category.name
FROM
    category
INNER JOIN film_category USING (category_id)
INNER JOIN film USING (film_id)
INNER JOIN inventory USING (film_id)
INNER JOIN rental USING (inventory_id)
INNER JOIN customer USING (customer_id)
INNER JOIN address USING (address_id)
INNER JOIN city USING (city_id)
WHERE
    LOWER(city.city) LIKE 'a%' OR city.city LIKE '%-%'
GROUP BY
    category.name
ORDER BY
    SUM(CAST((julianday(rental.return_date) - julianday(rental.rental_date)) * 24 AS INTEGER)) DESC
LIMIT
    1;