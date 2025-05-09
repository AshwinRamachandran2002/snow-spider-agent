/*------------------------------------------------------------
  Top-selling product (excluding the Henley itself) among users
  who purchased “YouTube Men’s Vintage Henley” during July 2017
-------------------------------------------------------------*/
WITH july_sessions AS (          -- 1.  All July-2017 sessions
    SELECT "fullVisitorId",
           "hits"
    FROM  GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170701
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
purchased_items AS (            -- 2.  Flatten to individual bought items
    SELECT 
        s."fullVisitorId"                AS visitor_id,
        prod.value:"v2ProductName"::STRING   AS product_name,
        COALESCE( prod.value:"productQuantity"::INTEGER , 1 ) AS qty
    FROM  july_sessions  AS s,
          LATERAL FLATTEN( INPUT => s."hits")                AS hit,            -- split hits
          LATERAL FLATTEN( INPUT => hit.value:"product")     AS prod            -- split products
    WHERE hit.value:"eCommerceAction":"action_type"::STRING = '6'               -- completed purchase
),                                                                
henley_buyers AS (              -- 3.  Customers who bought the Henley
    SELECT DISTINCT visitor_id
    FROM   purchased_items
    WHERE  ILIKE(product_name, '%youtube%')
       AND ILIKE(product_name, '%vintage%')
       AND ILIKE(product_name, '%henley%')
),                                                                
other_purchases AS (            -- 4.  Their other item purchases (excl. Henley)
    SELECT  p.product_name,
            SUM(p.qty) AS total_qty
    FROM    purchased_items  p
    JOIN    henley_buyers   h   ON p.visitor_id = h.visitor_id
    WHERE NOT ( ILIKE(p.product_name, '%youtube%')
             AND ILIKE(p.product_name, '%vintage%')
             AND ILIKE(p.product_name, '%henley%') )
    GROUP BY p.product_name
)                               -- 5.  Pick the top-selling product
SELECT  product_name,
        total_qty
FROM    other_purchases
ORDER BY total_qty DESC NULLS LAST
LIMIT 1;