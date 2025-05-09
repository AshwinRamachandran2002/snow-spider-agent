WITH monthly_sales AS (
    /* 1.  France-only monthly sales for 2019‑2020 that used  
           a qualifying promotion and channel                                    */
    SELECT
        s.prod_id,
        CAST(strftime('%m', s.time_id) AS INTEGER)              AS month,
        CAST(strftime('%Y', s.time_id) AS INTEGER)              AS year,
        SUM(s.amount_sold)                                      AS amount
    FROM       sales       AS s
    JOIN       customers   AS cu ON s.cust_id   = cu.cust_id
    JOIN       countries   AS co ON cu.country_id = co.country_id
    JOIN       promotions  AS pr ON s.promo_id  = pr.promo_id
    JOIN       channels    AS ch ON s.channel_id = ch.channel_id
    WHERE      co.country_name        = 'France'
          AND  pr.promo_total_id      = 1
          AND  ch.channel_total_id    = 1
          AND  CAST(strftime('%Y', s.time_id) AS INTEGER) IN (2019, 2020)
    GROUP BY   s.prod_id, year, month
),
pivot AS (
    /* 2.  Put 2019 and 2020 amounts side‑by‑side                           */
    SELECT
        prod_id,
        month,
        SUM(CASE WHEN year = 2019 THEN amount END)  AS amt_2019,
        SUM(CASE WHEN year = 2020 THEN amount END)  AS amt_2020
    FROM   monthly_sales
    GROUP  BY prod_id, month
),
projected AS (
    /* 3.  Project 2021 sales in local currency using the 19‑>20 growth rate */
    SELECT
        prod_id,
        month,
        /* projected_2021 = 2020 * (1 + (2020‑2019)/2019)  */
        (amt_2020 * (1.0 + ((amt_2020 - amt_2019) / amt_2019))) AS proj_2021_local
    FROM   pivot
    WHERE  amt_2019 > 0
       AND amt_2020 IS NOT NULL
),
proj_usd AS (
    /* 4.  Convert the projection to USD with 2021 exchange rates            */
    SELECT
        p.month,
        p.prod_id,
        p.proj_2021_local * c.to_us                    AS proj_2021_usd
    FROM   projected AS p
    JOIN   currency  AS c
           ON c.country = 'France'
          AND c.year    = 2021
          AND c.month   = p.month
)
/* 5.  Average the USD projections by month                                  */
SELECT
    month,
    AVG(proj_2021_usd) AS avg_projected_sales_usd
FROM   proj_usd
GROUP  BY month
ORDER  BY month;