SELECT 
  ROUND(
        CAST(good.good_count AS REAL) * 100.0 / total.total_count
       , 4) AS percent_good_bronx
FROM (
        SELECT COUNT(*) AS good_count
        FROM "trees"
        WHERE "boroname" = 'Bronx'
          AND "health"  = 'Good'
     ) AS good,
     (
        SELECT COUNT(*) AS total_count
        FROM "trees"
        WHERE "boroname" = 'Bronx'
     ) AS total;