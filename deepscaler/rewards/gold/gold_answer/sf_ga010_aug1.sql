-- Task: Provide the total number of sessions per channel from December 1 to December 5, 2020.

SELECT
    channel AS "Channel",
    COUNT(*) AS "Number_of_Sessions"
FROM (
    SELECT DISTINCT
        t."USER_PSEUDO_ID",
        t."EVENT_TIMESTAMP",
        CASE
            WHEN t."TRAFFIC_SOURCE":"medium"::STRING IS NULL OR t."TRAFFIC_SOURCE":"source"::STRING IS NULL THEN 'Unassigned'
            WHEN LOWER(t."TRAFFIC_SOURCE":"medium"::STRING) = 'organic' 
                 AND LOWER(t."TRAFFIC_SOURCE":"source"::STRING) IN ('google', 'bing', 'duckduckgo', 'ecosia', 'yahoo', 'baidu', 'yandex') THEN 'Organic Search'
            WHEN LOWER(t."TRAFFIC_SOURCE":"medium"::STRING) IN ('cpc', 'ppc', 'paidsearch') 
                 AND LOWER(t."TRAFFIC_SOURCE":"source"::STRING) IN ('google', 'bing', 'duckduckgo', 'ecosia', 'yahoo', 'baidu', 'yandex') THEN 'Paid Search'
            WHEN LOWER(t."TRAFFIC_SOURCE":"medium"::STRING) = 'referral' THEN 'Referral'
            WHEN LOWER(t."TRAFFIC_SOURCE":"medium"::STRING) IN ('(none)', '(not set)') 
                 AND LOWER(t."TRAFFIC_SOURCE":"source"::STRING) = '(direct)' THEN 'Direct'
            ELSE 'Unassigned'
        END AS channel
    FROM (
        SELECT * FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20201201"
        UNION ALL
        SELECT * FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20201202"
        UNION ALL
        SELECT * FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20201203"
        UNION ALL
        SELECT * FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20201204"
        UNION ALL
        SELECT * FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20201205"
    ) t
    WHERE t."EVENT_NAME" = 'session_start'
) 
GROUP BY channel
ORDER BY "Number_of_Sessions" DESC NULLS LAST, channel ASC
LIMIT 100;