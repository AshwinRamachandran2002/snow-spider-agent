WITH weekly AS (
  /* weekly-level sales for each calendar year */
  SELECT
    "calendar_year"              AS year,
    "week_date",
    SUM("sales")                 AS week_sales
  FROM "cleaned_weekly_sales"
  GROUP BY "calendar_year", "week_date"
),
years AS (
  SELECT DISTINCT year FROM weekly
)
SELECT
  y.year,
  /* 4 weeks on or before 15-June */
  (SELECT SUM(week_sales)
     FROM (
           SELECT week_sales
           FROM weekly w1
           WHERE w1.year = y.year
             AND w1."week_date" <= printf('%d-06-15', y.year)
           ORDER BY w1."week_date" DESC
           LIMIT 4)
  ) AS sales_before,
  /* 4 weeks after 15-June */
  (SELECT SUM(week_sales)
     FROM (
           SELECT week_sales
           FROM weekly w2
           WHERE w2.year = y.year
             AND w2."week_date" > printf('%d-06-15', y.year)
           ORDER BY w2."week_date"
           LIMIT 4)
  ) AS sales_after,
  ROUND(
        (
          (SELECT SUM(week_sales)
             FROM (
                   SELECT week_sales
                   FROM weekly w3
                   WHERE w3.year = y.year
                     AND w3."week_date" > printf('%d-06-15', y.year)
                   ORDER BY w3."week_date"
                   LIMIT 4)
          )
          -
          (SELECT SUM(week_sales)
             FROM (
                   SELECT week_sales
                   FROM weekly w4
                   WHERE w4.year = y.year
                     AND w4."week_date" <= printf('%d-06-15', y.year)
                   ORDER BY w4."week_date" DESC
                   LIMIT 4)
          )
        ) * 100.0 /
        (SELECT SUM(week_sales)
           FROM (
                 SELECT week_sales
                 FROM weekly w5
                 WHERE w5.year = y.year
                   AND w5."week_date" <= printf('%d-06-15', y.year)
                 ORDER BY w5."week_date" DESC
                 LIMIT 4)
        ), 4
  ) AS pct_change
FROM years y
ORDER BY y.year;