SELECT
    c.name AS category_name
FROM category AS c
JOIN film_category       AS fc ON fc.category_id = c.category_id
JOIN film                AS f  ON f.film_id       = fc.film_id
JOIN inventory           AS i  ON i.film_id       = f.film_id
JOIN rental              AS r  ON r.inventory_id  = i.inventory_id
JOIN customer            AS cu ON cu.customer_id  = r.customer_id
JOIN address             AS a  ON a.address_id    = cu.address_id
JOIN city                AS ci ON ci.city_id      = a.city_id
WHERE (ci.city LIKE 'A%' OR ci.city LIKE '%-%')      -- city starts with 'A' or contains a hyphen
  AND r.return_date IS NOT NULL                      -- ensure rental was returned
GROUP BY c.category_id, c.name
ORDER BY SUM((julianday(r.return_date) - julianday(r.rental_date)) * 24.0) DESC,
         c.name
LIMIT 1;