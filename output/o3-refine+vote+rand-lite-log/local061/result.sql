WITH filtered_sales AS (           -- 1.  France‑only, promo_total_id=1, channel_total_id=1
    SELECT
        s.prod_id,
        t.calendar_month_number   AS month,
        t.calendar_year           AS year,
        SUM(s.amount_sold)        AS total_amount
    FROM       sales      AS s
    JOIN times            AS t   ON s.time_id   = t.time_id
    JOIN promotions       AS p   ON s.promo_id  = p.promo_id  AND p.promo_total_id   = 1
    JOIN channels         AS ch  ON s.channel_id= ch.channel_id AND ch.channel_total_id = 1
    JOIN customers        AS cu  ON s.cust_id   = cu.cust_id
    JOIN countries        AS co  ON cu.country_id = co.country_id
    WHERE co.country_name = 'France'
      AND t.calendar_year IN (2019,2020)
    GROUP BY s.prod_id, t.calendar_month_number, t.calendar_year
),
pivot AS (                       -- 2.  Place 2019 and 2020 numbers side by side
    SELECT
        s20.prod_id,
        s20.month,
        COALESCE(s19.total_amount,0) AS amt_2019,
        s20.total_amount             AS amt_2020
    FROM filtered_sales AS s20
    LEFT JOIN filtered_sales AS s19
           ON s19.prod_id = s20.prod_id
          AND s19.month   = s20.month
          AND s19.year    = 2019
    WHERE s20.year = 2020
),
projected AS (                   -- 3.  Project 2021 sales per product & month
    SELECT
        prod_id,
        month,
        CASE
            WHEN amt_2019 > 0
            THEN amt_2020 * (1.0 + (amt_2020 - amt_2019) / amt_2019)  --  apply growth rate
            ELSE NULL                                                 --  no projection if 2019 = 0
        END AS proj_2021_local
    FROM pivot
)
SELECT
       cur.month                                            AS month,
       ROUND(AVG(proj.proj_2021_local * cur.to_us),4)       AS avg_projected_sales_usd
FROM   projected          AS proj
JOIN   currency           AS cur
       ON cur.country = 'France'
      AND cur.year    = 2021
      AND cur.month   = proj.month
GROUP  BY cur.month
ORDER  BY cur.month;