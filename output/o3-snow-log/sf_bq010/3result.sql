/*-----------------------------------------------------------
 Goal : Top–selling product (by quantity) that was bought by the
        same visitors who purchased “YouTube Men’s … Henley”
        during July-2017, excluding every Henley product itself.
-----------------------------------------------------------*/
WITH july_sessions AS (          -- 1.  all July-2017 session rows
      SELECT "fullVisitorId"
           , "hits"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170701
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170702
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170703
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170704
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170705
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170706
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170707
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170708
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170709
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170710
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170711
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170712
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170713
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170714
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170715
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170716
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170717
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170718
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170719
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170720
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170721
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170722
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170723
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170724
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170725
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170726
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170727
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170728
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170729
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170730
 UNION ALL SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170731
),

purchased_products AS (          -- 2. explode products actually purchased
    SELECT
        js."fullVisitorId"                             AS visitor_id ,
        prod.value:"v2ProductName"::STRING             AS product_name ,
        COALESCE(prod.value:"productQuantity"::INT,1)  AS qty ,
        prod.value:"productRevenue"::INT               AS revenue         -- used only for purchase filter
    FROM july_sessions           js
         ,LATERAL FLATTEN(input => js."hits")          hit
         ,LATERAL FLATTEN(input => hit.value:"product") prod
    WHERE COALESCE(prod.value:"productRevenue"::INT,0) > 0        -- purchase only
),

henley_buyers AS (              -- 3. visitors who bought any Henley product
    SELECT DISTINCT visitor_id
    FROM purchased_products
    WHERE LOWER(product_name) LIKE '%youtube%'      -- keep “YouTube” products
      AND LOWER(product_name) LIKE '%henley%'       -- and containing “henley”
),

other_products AS (             -- 4. all OTHER products bought by those visitors
    SELECT
        pp.product_name ,
        SUM(pp.qty) AS total_qty
    FROM purchased_products pp
    JOIN henley_buyers hb
      ON pp.visitor_id = hb.visitor_id
    WHERE LOWER(pp.product_name) NOT LIKE '%henley%'      -- exclude Henley itself
    GROUP BY pp.product_name
)

-- 5. top-selling (by quantity)
SELECT product_name      AS top_selling_product ,
       total_qty         AS units_sold
FROM   other_products
ORDER BY total_qty DESC NULLS LAST
LIMIT 1;