-- Task: Please help me find the total rental hours for each film category in cities where the city's name either starts with "A" or contains a hyphen.
SELECT
    CATEGORY."name",
    SUM(CAST(DATEDIFF('hour', TRY_TO_TIMESTAMP(RENTAL."rental_date"), TRY_TO_TIMESTAMP(RENTAL."return_date")) AS INTEGER)) AS total_rental_hours
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
    total_rental_hours DESC;