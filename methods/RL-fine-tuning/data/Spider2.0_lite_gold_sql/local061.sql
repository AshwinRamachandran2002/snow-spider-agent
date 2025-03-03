WITH sales_annual AS (
  SELECT
    s.prod_id,
    t.calendar_year,
    t.calendar_month_number,
    SUM(s.amount_sold) AS total_sales
  FROM
    sales s
  JOIN customers cu ON s.cust_id = cu.cust_id
  JOIN countries c ON cu.country_id = c.country_id
  JOIN promotions p ON s.promo_id = p.promo_id
  JOIN channels ch ON s.channel_id = ch.channel_id
  JOIN times t ON s.time_id = t.time_id
  WHERE
    c.country_name = 'France'
    AND p.promo_total_id = 1
    AND ch.channel_total_id = 1
    AND t.calendar_year IN (2019, 2020)
  GROUP BY
    s.prod_id,
    t.calendar_year,
    t.calendar_month_number
),
prod_months AS (
  SELECT DISTINCT prod_id, calendar_month_number FROM sales_annual
),
sales_2019 AS (
  SELECT
    prod_id,
    calendar_month_number,
    total_sales
  FROM
    sales_annual
  WHERE calendar_year = 2019
),
sales_2020 AS (
  SELECT
    prod_id,
    calendar_month_number,
    total_sales
  FROM
    sales_annual
  WHERE calendar_year = 2020
),
sales_growth AS (
  SELECT
    pm.prod_id,
    pm.calendar_month_number,
    COALESCE(s2019.total_sales, 0) AS sales_2019,
    COALESCE(s2020.total_sales, 0) AS sales_2020
  FROM
    prod_months pm
  LEFT JOIN sales_2019 s2019 ON
    pm.prod_id = s2019.prod_id AND
    pm.calendar_month_number = s2019.calendar_month_number
  LEFT JOIN sales_2020 s2020 ON
    pm.prod_id = s2020.prod_id AND
    pm.calendar_month_number = s2020.calendar_month_number
),
sales_growth_rate AS (
  SELECT
    sg.prod_id,
    sg.calendar_month_number,
    sg.sales_2019,
    sg.sales_2020,
    CASE
      WHEN sg.sales_2019 = 0 THEN 0
      ELSE (sg.sales_2020 - sg.sales_2019) / sg.sales_2019
    END AS growth_rate
  FROM
    sales_growth sg
),
projected_sales AS (
  SELECT
    sgr.prod_id,
    sgr.calendar_month_number,
    sgr.sales_2020,
    sgr.growth_rate,
    sgr.sales_2020 * (1 + sgr.growth_rate) AS projected_sales_2021
  FROM
    sales_growth_rate sgr
),
projected_sales_usd AS (
  SELECT
    ps.prod_id,
    ps.calendar_month_number,
    ps.projected_sales_2021,
    c.to_us,
    ps.projected_sales_2021 * c.to_us AS projected_sales_2021_usd
  FROM
    projected_sales ps
  JOIN currency c ON
    c.country = 'France' AND
    c.year = 2021 AND
    c.month = ps.calendar_month_number
)
SELECT
  psu.calendar_month_number AS Month_num,
  MAX(t.calendar_month_name) AS Month,
  ROUND(AVG(psu.projected_sales_2021_usd), 4) AS Average_Projected_Sales_USD
FROM
  projected_sales_usd psu
JOIN times t ON
  t.calendar_year = 2021 AND t.calendar_month_number = psu.calendar_month_number
GROUP BY
  psu.calendar_month_number
ORDER BY
  psu.calendar_month_number;