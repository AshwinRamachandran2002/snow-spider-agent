-- Task: List the number of rentals for each store by year and month. Provide the store ID, the year, the month, and the total number of rentals. Limit the results to the first 100 entries.
SELECT 
  EXTRACT(YEAR FROM TO_TIMESTAMP("re"."rental_date", 'YYYY-MM-DD HH24:MI:SS.FF')) AS "year", 
  EXTRACT(MONTH FROM TO_TIMESTAMP("re"."rental_date", 'YYYY-MM-DD HH24:MI:SS.FF')) AS "rental_month", 
  "st"."store_id", 
  COUNT("re"."rental_id") AS "total_rentals"
FROM 
  SQLITE_SAKILA.SQLITE_SAKILA.RENTAL "re"
  JOIN SQLITE_SAKILA.SQLITE_SAKILA.STAFF "st" 
    ON "re"."staff_id" = "st"."staff_id"
GROUP BY 
  EXTRACT(YEAR FROM TO_TIMESTAMP("re"."rental_date", 'YYYY-MM-DD HH24:MI:SS.FF')),
  EXTRACT(MONTH FROM TO_TIMESTAMP("re"."rental_date", 'YYYY-MM-DD HH24:MI:SS.FF')),
  "st"."store_id"
LIMIT 100;