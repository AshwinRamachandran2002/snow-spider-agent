SELECT
  ROUND(
      100.0 * (
          SELECT COUNT(DISTINCT r.customer_id)
          FROM   rental      AS r
          JOIN   inventory   AS i  ON i.inventory_id = r.inventory_id
          JOIN   film_actor  AS fa ON fa.film_id     = i.film_id
          WHERE  fa.actor_id IN (
                SELECT fa2.actor_id
                FROM   film_actor AS fa2
                JOIN   inventory  AS i2 ON i2.film_id      = fa2.film_id
                JOIN   rental     AS r2 ON r2.inventory_id = i2.inventory_id
                GROUP  BY fa2.actor_id
                ORDER  BY COUNT(r2.rental_id) DESC
                LIMIT  5
          )
      ) / (SELECT COUNT(*) FROM customer),
      4
  ) AS percentage_customers_top5;