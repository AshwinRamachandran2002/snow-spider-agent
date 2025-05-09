WITH
/* -----------------------------------------------------------
   1.  Total sales for every attribute-value in the 12 weeks
       BEFORE and AFTER the Monday closest to 15-Jun-2020
   ----------------------------------------------------------- */
before AS (
    SELECT  region,
            platform,
            age_band,
            demographic,
            customer_type,
            SUM(sales) AS sales_before
    FROM   cleaned_weekly_sales
    WHERE  week_date BETWEEN '2020-03-23'    -- 12 Mondays before
                         AND '2020-06-07'
    GROUP  BY region, platform, age_band, demographic, customer_type
),
after  AS (
    SELECT  region,
            platform,
            age_band,
            demographic,
            customer_type,
            SUM(sales) AS sales_after
    FROM   cleaned_weekly_sales
    WHERE  week_date BETWEEN '2020-06-22'    -- 12 Mondays after
                         AND '2020-09-07'
    GROUP  BY region, platform, age_band, demographic, customer_type
),
/* -----------------------------------------------------------
   2.  % change for every individual attribute-value
   ----------------------------------------------------------- */
pct_change AS (
    SELECT  b.region,
            b.platform,
            b.age_band,
            b.demographic,
            b.customer_type,
            100.0 * (a.sales_after - b.sales_before) / b.sales_before AS pct_change
    FROM   before b
    JOIN   after  a
           USING (region, platform, age_band, demographic, customer_type)
),
/* -----------------------------------------------------------
   3.  Average % change inside each attribute TYPE
   ----------------------------------------------------------- */
attr_avgs AS (
      /* Region */
      SELECT 'region' AS attribute_type,
             AVG(pct_change) AS avg_pct_change
      FROM  (SELECT region, AVG(pct_change) AS pct_change
             FROM  pct_change GROUP BY region)

      UNION ALL
      /* Platform */
      SELECT 'platform',
             AVG(pct_change)
      FROM  (SELECT platform, AVG(pct_change) AS pct_change
             FROM  pct_change GROUP BY platform)

      UNION ALL
      /* Age band */
      SELECT 'age_band',
             AVG(pct_change)
      FROM  (SELECT age_band, AVG(pct_change) AS pct_change
             FROM  pct_change GROUP BY age_band)

      UNION ALL
      /* Demographic */
      SELECT 'demographic',
             AVG(pct_change)
      FROM  (SELECT demographic, AVG(pct_change) AS pct_change
             FROM  pct_change GROUP BY demographic)

      UNION ALL
      /* Customer type */
      SELECT 'customer_type',
             AVG(pct_change)
      FROM  (SELECT customer_type, AVG(pct_change) AS pct_change
             FROM  pct_change GROUP BY customer_type)
)
/* -----------------------------------------------------------
   4.  Final result – all attribute types with their average
       % change, ordered so the most negative impact is first
   ----------------------------------------------------------- */
SELECT attribute_type,
       ROUND(avg_pct_change, 2) AS avg_pct_change
FROM   attr_avgs
ORDER  BY avg_pct_change;   -- first row = highest negative impact