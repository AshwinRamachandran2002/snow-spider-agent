-- Task: In the Iowa Liquor Sales dataset, from January 1, 2022 through the last fully completed month, calculate the total monthly volume of liquor sold in gallons for each month.

SELECT
  TO_CHAR("date", 'YYYY-MM') AS "month",
  SUM("volume_sold_gallons") AS "total_monthly_volume"
FROM
  IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES."SALES"
WHERE
  "date" >= '2022-01-01'
  AND TO_CHAR("date", 'YYYY-MM') < TO_CHAR(CURRENT_DATE(), 'YYYY-MM')
GROUP BY
  TO_CHAR("date", 'YYYY-MM')
ORDER BY
  "month" ASC;