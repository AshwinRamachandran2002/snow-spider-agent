SELECT
  year AS Year,
  ROUND(
    (
      (SUM(CASE WHEN date_string BETWEEN date(year || '-06-15') AND date(year || '-07-12') THEN sales ELSE 0 END) -
       SUM(CASE WHEN date_string BETWEEN date(year || '-05-18') AND date(year || '-06-14') THEN sales ELSE 0 END)
      ) * 100.0 /
      SUM(CASE WHEN date_string BETWEEN date(year || '-05-18') AND date(year || '-06-14') THEN sales ELSE 0 END)
    ), 4
  ) AS Percentage_Change_Sales
FROM
(
  SELECT
    week_date,
    sales,
    '20' || SUBSTR(week_date, sp2 +1, 2) AS year,
    date(
      '20' || SUBSTR(week_date, sp2 +1, 2) || '-' ||
      printf('%02d', CAST(SUBSTR(week_date, sp1 +1, sp2 - sp1 -1) AS INTEGER)) || '-' ||
      printf('%02d', CAST(SUBSTR(week_date, 1, sp1 -1) AS INTEGER))
    ) AS date_string
  FROM
    (SELECT week_date, sales,
     INSTR(week_date, '/') AS sp1,
     INSTR(SUBSTR(week_date, INSTR(week_date, '/') +1), '/') + INSTR(week_date, '/') AS sp2
     FROM "weekly_sales"
    )
)
WHERE year IN ('2018', '2019', '2020')
GROUP BY year;