SELECT 
    CAST(m1."year" AS INT) AS start_year,
    COUNT(*)               AS films_in_10yr_window
FROM   Movie AS m1
JOIN   Movie AS m2
       ON CAST(m2."year" AS INT) 
          BETWEEN CAST(m1."year" AS INT) 
              AND CAST(m1."year" AS INT) + 9
GROUP  BY start_year
ORDER  BY films_in_10yr_window DESC, start_year
LIMIT 1;