WITH france_sales AS (
    /* 1.  France sales for 2019‑2020 in USD (promo_total_id = 1 , channel_total_id = 1 ) */
    SELECT  
        CAST(strftime('%Y', s.time_id) AS INTEGER)  AS year ,
        CAST(strftime('%m', s.time_id) AS INTEGER)  AS month ,
        s.amount_sold * COALESCE(cy.to_us , 1)      AS amt_usd
    FROM   sales       s
    JOIN   customers   cu  ON cu.cust_id   = s.cust_id
    JOIN   countries   co  ON co.country_id= cu.country_id
    JOIN   promotions  pr  ON pr.promo_id  = s.promo_id   AND pr.promo_total_id   = 1
    JOIN   channels    ch  ON ch.channel_id= s.channel_id AND ch.channel_total_id = 1
    LEFT   JOIN currency  cy
           ON cy.country = co.country_name
          AND cy.year    = CAST(strftime('%Y', s.time_id) AS INTEGER)
          AND cy.month   = CAST(strftime('%m', s.time_id) AS INTEGER)
    WHERE  co.country_name = 'France'
      AND  CAST(strftime('%Y', s.time_id) AS INTEGER) IN (2019, 2020)
),
monthly_avg AS (
    /* 2.  Average monthly sales for each year                     */
    SELECT year , month , AVG(amt_usd) AS avg_usd
    FROM   france_sales
    GROUP  BY year , month
),
growth AS (
    /* 3.  2019‑>2020 growth factor per month                      */
    SELECT  m20.month ,
            m20.avg_usd                          AS avg2020 ,
            m19.avg_usd                          AS avg2019 ,
            CASE 
                 WHEN m19.avg_usd IS NOT NULL AND m19.avg_usd<>0
                 THEN m20.avg_usd / m19.avg_usd
            END                                  AS growth_factor
    FROM    monthly_avg m20
    LEFT    JOIN monthly_avg m19
           ON m19.year  = 2019
          AND m19.month = m20.month
    WHERE   m20.year = 2020
),
proj_2021 AS (
    /* 4.  Projected 2021 average per month                        */
    SELECT  2021                 AS year ,
            month ,
            avg2020 * growth_factor   AS proj_avg_usd
    FROM    growth
    WHERE   growth_factor IS NOT NULL
),
ordered AS (
    /* 5.  Rank the projected monthly averages to obtain median    */
    SELECT  proj_avg_usd ,
            ROW_NUMBER() OVER (ORDER BY proj_avg_usd)          AS rn ,
            COUNT(*)    OVER ()                                AS cnt
    FROM    proj_2021
)
SELECT  ROUND(
        CASE 
             WHEN cnt % 2 = 1
             THEN (SELECT proj_avg_usd FROM ordered WHERE rn = (cnt+1)/2)
             ELSE (SELECT AVG(proj_avg_usd) FROM ordered WHERE rn IN (cnt/2, cnt/2+1))
        END
        ,4) AS median_projected_avg_monthly_sales_2021_usd
FROM    ordered
LIMIT   1;