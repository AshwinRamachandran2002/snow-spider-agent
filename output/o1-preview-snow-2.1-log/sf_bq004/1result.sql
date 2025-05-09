WITH union_tables AS (
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170701"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170702"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170703"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170704"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170705"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170706"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170707"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170708"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170709"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170710"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170711"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170712"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170713"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170714"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170715"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170716"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170717"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170718"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170719"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170720"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170721"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170722"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170723"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170724"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170725"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170726"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170727"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170728"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170729"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170730"
    UNION ALL
    SELECT "fullVisitorId", "visitId", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170731"
),
youtube_sessions AS (
    SELECT DISTINCT t."fullVisitorId", t."visitId"
    FROM union_tables t,
         LATERAL FLATTEN(INPUT => t."hits") AS hits,
         LATERAL FLATTEN(INPUT => hits.value:"product") AS hits_product
    WHERE hits_product.value:"v2ProductName"::STRING ILIKE '%YouTube%'
)
SELECT other_hits_product.value:"v2ProductName"::STRING AS "Product_Name", COUNT(*) AS "Purchase_Count"
FROM union_tables t
JOIN youtube_sessions ys
  ON t."fullVisitorId" = ys."fullVisitorId" AND t."visitId" = ys."visitId",
  LATERAL FLATTEN(INPUT => t."hits") AS other_hits,
  LATERAL FLATTEN(INPUT => other_hits.value:"product") AS other_hits_product
WHERE other_hits_product.value:"v2ProductName"::STRING NOT ILIKE '%YouTube%'
GROUP BY "Product_Name"
ORDER BY "Purchase_Count" DESC NULLS LAST
LIMIT 1;