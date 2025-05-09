WITH france          AS (
     SELECT country_id 
     FROM   countries 
     WHERE  country_name = 'France'
),
/* France – product/month sales for 2019 */
sales_2019 AS (
     SELECT strftime('%m', s.time_id)        AS month ,
            s.prod_id,
            SUM(s.amount_sold)              AS sales19
     FROM   sales       AS s
     JOIN   customers   AS c  ON c.cust_id   = s.cust_id
     JOIN   promotions  AS p  ON p.promo_id  = s.promo_id
     JOIN   channels    AS ch ON ch.channel_id = s.channel_id
     WHERE  c.country_id       = (SELECT country_id FROM france)
       AND  p.promo_total_id   = 1
       AND  ch.channel_total_id= 1
       AND  strftime('%Y', s.time_id) = '2019'
     GROUP BY month , s.prod_id
),
/* France – product/month sales for 2020 */
sales_2020 AS (
     SELECT strftime('%m', s.time_id)        AS month ,
            s.prod_id,
            SUM(s.amount_sold)              AS sales20
     FROM   sales       AS s
     JOIN   customers   AS c  ON c.cust_id   = s.cust_id
     JOIN   promotions  AS p  ON p.promo_id  = s.promo_id
     JOIN   channels    AS ch ON ch.channel_id = s.channel_id
     WHERE  c.country_id       = (SELECT country_id FROM france)
       AND  p.promo_total_id   = 1
       AND  ch.channel_total_id= 1
       AND  strftime('%Y', s.time_id) = '2020'
     GROUP BY month , s.prod_id
),
/* Project 2021 sales applying 19→20 growth */
proj_2021 AS (
     SELECT s20.month,
            s20.prod_id,
            s20.sales20 * 
            (1 + CASE 
                    WHEN s19.sales19 IS NOT NULL AND s19.sales19 <> 0
                         THEN (s20.sales20 - s19.sales19) * 1.0 / s19.sales19
                    ELSE 0
                 END)                         AS proj_sales_2021
     FROM   sales_2020 s20
     LEFT JOIN sales_2019 s19
            ON s19.month   = s20.month
           AND s19.prod_id = s20.prod_id
),
/* Convert projected 2021 sales to USD with 2021 FX rate */
proj_2021_usd AS (
     SELECT p.month,
            p.prod_id,
            p.proj_sales_2021 / cu.to_us     AS proj_sales_2021_usd
     FROM   proj_2021  AS p
     JOIN   currency   AS cu
            ON cu.country = 'France'
           AND cu.year    = 2021
           AND cu.month   = CAST(p.month AS INTEGER)
)
/* Average projected monthly sales (USD) */
SELECT   month,
         ROUND(AVG(proj_sales_2021_usd),4)   AS avg_projected_sales_usd_2021
FROM     proj_2021_usd
GROUP BY month
ORDER BY month;