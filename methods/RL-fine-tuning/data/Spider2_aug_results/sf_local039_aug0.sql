-- Task: Find the name of the film category that has the highest total rental hours, where the total rental hours are calculated by summing the duration (in hours) of all rentals of films in that category, for rentals made by customers located in cities whose names either start with the letter 'A' (case-insensitive) or contain a hyphen.
SELECT
    CATEGORY."name"
FROM
    PAGILA.PAGILA.CATEGORY
INNER JOIN PAGILA.PAGILA.FILM_CATEGORY USING ("category_id")
INNER JOIN PAGILA.PAGILA.FILM USING ("film_id")
INNER JOIN PAGILA.PAGILA.INVENTORY USING ("film_id")
INNER JOIN PAGILA.PAGILA.RENTAL USING ("inventory_id")
INNER JOIN PAGILA.PAGILA.CUSTOMER USING ("customer_id")
INNER JOIN PAGILA.PAGILA.ADDRESS USING ("address_id")
INNER JOIN PAGILA.PAGILA.CITY USING ("city_id")
WHERE
    LOWER(CITY."city") LIKE 'a%' OR CITY."city" LIKE '%-%'
GROUP BY
    CATEGORY."name"
ORDER BY
    SUM(CAST((DATEDIFF('hour', TRY_TO_TIMESTAMP(RENTAL."rental_date"), TRY_TO_TIMESTAMP(RENTAL."return_date"))) AS INTEGER)) DESC
LIMIT
    1;