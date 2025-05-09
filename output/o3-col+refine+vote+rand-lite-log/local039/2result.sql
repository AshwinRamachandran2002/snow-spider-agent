SELECT ca.name AS category_name
FROM category AS ca
JOIN (
    SELECT fc.category_id,
           SUM((julianday(r.return_date) - julianday(r.rental_date)) * 24) AS total_hours
    FROM rental        AS r
    JOIN inventory     AS i  ON r.inventory_id  = i.inventory_id
    JOIN film_category AS fc ON i.film_id       = fc.film_id
    JOIN customer      AS cu ON r.customer_id   = cu.customer_id
    JOIN address       AS a  ON cu.address_id   = a.address_id
    JOIN city          AS c  ON a.city_id       = c.city_id
    WHERE (c.city LIKE 'A%' OR c.city LIKE '%-%')
      AND r.return_date IS NOT NULL
    GROUP BY fc.category_id
    ORDER BY total_hours DESC
    LIMIT 1
) AS top_cat
ON ca.category_id = top_cat.category_id;