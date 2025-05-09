-- 1) Get every July-2017 session, 2) explode the product rows, 
-- 3) find the visitors who bought any YouTube product, 
-- 4) among those visitors aggregate the quantities of the other products, 
-- 5) keep the product with the greatest total quantity
WITH july_purchases AS (

    SELECT
        s."fullVisitorId"                               AS visitor_id,
        p.value:"v2ProductName" :: STRING               AS product_name,
        p.value:"productQuantity" :: INTEGER            AS quantity
    FROM (

        SELECT "fullVisitorId","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170701
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

    )  s,
    LATERAL FLATTEN ( input => s."hits" )       h,
    LATERAL FLATTEN ( input => h.value:"product") p
    WHERE p.value:"productQuantity" :: INTEGER > 0
),

youtube_buyers AS (
    SELECT DISTINCT visitor_id
    FROM   july_purchases
    WHERE  LOWER(product_name) LIKE '%youtube%'
),

other_products AS (
    SELECT
        jp.product_name,
        SUM(jp.quantity) AS total_qty
    FROM   july_purchases  jp
    JOIN   youtube_buyers  yb
        ON jp.visitor_id = yb.visitor_id
    WHERE  LOWER(jp.product_name) NOT LIKE '%youtube%'
    GROUP BY jp.product_name
)

SELECT
    product_name,
    total_qty
FROM   other_products
ORDER BY total_qty DESC NULLS LAST
LIMIT 1;