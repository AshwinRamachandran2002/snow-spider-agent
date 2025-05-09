WITH fr_2019 AS (
    SELECT t.calendar_month_number AS month_num,
           SUM(s.amount_sold) / MAX(cur.to_us) AS usd_sales_2019
    FROM   sales       AS s
    JOIN   customers   AS cu  ON cu.cust_id    = s.cust_id
    JOIN   countries   AS co  ON co.country_id = cu.country_id
    JOIN   times       AS t   ON t.time_id     = s.time_id
    JOIN   channels    AS ch  ON ch.channel_id = s.channel_id
    JOIN   promotions  AS pr  ON pr.promo_id   = s.promo_id
    JOIN   currency    AS cur ON cur.country   = co.country_name
                              AND cur.year     = 2019
                              AND cur.month    = t.calendar_month_number
    WHERE  co.country_name     = 'France'
      AND  t.calendar_year     = 2019
      AND  ch.channel_total_id = 1
      AND  pr.promo_total_id   = 1
    GROUP  BY t.calendar_month_number
),
fr_2020 AS (
    SELECT t.calendar_month_number AS month_num,
           SUM(s.amount_sold) / MAX(cur.to_us) AS usd_sales_2020
    FROM   sales       AS s
    JOIN   customers   AS cu  ON cu.cust_id    = s.cust_id
    JOIN   countries   AS co  ON co.country_id = cu.country_id
    JOIN   times       AS t   ON t.time_id     = s.time_id
    JOIN   channels    AS ch  ON ch.channel_id = s.channel_id
    JOIN   promotions  AS pr  ON pr.promo_id   = s.promo_id
    JOIN   currency    AS cur ON cur.country   = co.country_name
                              AND cur.year     = 2020
                              AND cur.month    = t.calendar_month_number
    WHERE  co.country_name     = 'France'
      AND  t.calendar_year     = 2020
      AND  ch.channel_total_id = 1
      AND  pr.promo_total_id   = 1
    GROUP  BY t.calendar_month_number
),
proj_2021 AS (
    SELECT f19.month_num,
           (1 + (f20.usd_sales_2020 - f19.usd_sales_2019) / NULLIF(f19.usd_sales_2019,0))
           * f20.usd_sales_2020 AS projected_sales_2021
    FROM   fr_2019 f19
    JOIN   fr_2020 f20 ON f20.month_num = f19.month_num
),
ordered_vals AS (
    SELECT projected_sales_2021 AS val,
           ROW_NUMBER() OVER (ORDER BY projected_sales_2021) AS rn,
           COUNT(*)  OVER ()                                 AS cnt
    FROM   proj_2021
)
SELECT ROUND(AVG(val),4) AS median_projected_monthly_sales_usd
FROM   ordered_vals
WHERE  rn IN ((cnt + 1) / 2, (cnt + 2) / 2);