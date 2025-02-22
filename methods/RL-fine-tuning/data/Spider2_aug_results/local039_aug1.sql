-- Task: Please help me find the film category with the highest total rental hours.

SELECT
    category.name
FROM
    category
INNER JOIN film_category USING (category_id)
INNER JOIN film USING (film_id)
INNER JOIN inventory USING (film_id)
INNER JOIN rental USING (inventory_id)
GROUP BY
    category.name
ORDER BY
    SUM(CAST((julianday(rental.return_date) - julianday(rental.rental_date)) * 24 AS INTEGER)) DESC
LIMIT
    1;