SELECT ROUND(
         100.0 * (
           SELECT COUNT(DISTINCT r."customer_id")
           FROM   "rental"      AS r
           JOIN   "inventory"   USING ("inventory_id")
           JOIN   "film_actor"  USING ("film_id")
           WHERE  "actor_id" IN (
                   SELECT fa."actor_id"
                   FROM   "film_actor"  AS fa
                   JOIN   "inventory"   USING ("film_id")
                   JOIN   "rental"      USING ("inventory_id")
                   GROUP  BY fa."actor_id"
                   ORDER  BY COUNT(*) DESC
                   LIMIT 5
                 )
         ) /
         (SELECT COUNT(*) FROM "customer")
       , 4) AS "percentage_customers_top5_actors";