WITH home_sessions AS (
  SELECT DISTINCT 
    s.value:"value":"int_value"::STRING AS "ga_session_id"
  FROM 
    "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" t,
    LATERAL FLATTEN(input => t."EVENT_PARAMS") s,
    LATERAL FLATTEN(input => t."EVENT_PARAMS") f
  WHERE 
    t."EVENT_NAME" = 'page_view'
    AND s.value:"key"::STRING = 'ga_session_id'
    AND f.value:"key"::STRING = 'page_title'
    AND f.value:"value":"string_value"::STRING = 'Home'
),
sessions_with_checkout AS (
  SELECT DISTINCT 
    s.value:"value":"int_value"::STRING AS "ga_session_id"
  FROM 
    "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" t,
    LATERAL FLATTEN(input => t."EVENT_PARAMS") s,
    LATERAL FLATTEN(input => t."EVENT_PARAMS") f
  WHERE 
    t."EVENT_NAME" = 'page_view'
    AND s.value:"key"::STRING = 'ga_session_id'
    AND f.value:"key"::STRING = 'page_title'
    AND f.value:"value":"string_value"::STRING = 'Checkout Confirmation'
),
converted_sessions AS (
  SELECT DISTINCT hs."ga_session_id"
  FROM home_sessions hs
  INNER JOIN sessions_with_checkout sc ON hs."ga_session_id" = sc."ga_session_id"
)
SELECT 
  ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM home_sessions), 4) AS "Conversion_rate"
FROM converted_sessions;