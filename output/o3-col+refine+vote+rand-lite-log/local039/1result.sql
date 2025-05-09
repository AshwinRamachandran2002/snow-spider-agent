SELECT
    ct.name AS top_category,
    SUM(ROUND((julianday(r.return_date) - julianday(r.rental_date)) * 24, 4)) AS total_rental_hours
FROM          rental        AS r
JOIN          inventory     AS i   ON i.inventory_id   = r.inventory_id
JOIN          film_category AS fc  ON fc.film_id       = i.film_id
JOIN          category      AS ct  ON ct.category_id   = fc.category_id
JOIN          customer      AS cu  ON cu.customer_id   = r.customer_id
JOIN          address       AS a   ON a.address_id     = cu.address_id
JOIN          city          AS c   ON c.city_id        = a.city_id
WHERE         c.city LIKE 'A%' 
           OR c.city LIKE '%-%'
GROUP BY      ct.name
ORDER BY      total_rental_hours DESC
LIMIT 1;