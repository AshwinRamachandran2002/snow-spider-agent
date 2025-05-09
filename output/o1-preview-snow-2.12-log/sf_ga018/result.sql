WITH categories AS (
  SELECT ARRAY_CONSTRUCT(
    UPPER('ACCESSORIES'),
    UPPER('APPAREL'),
    UPPER('BRANDS'),
    UPPER('CAMPUS COLLECTION'),
    UPPER('DRINKWARE'),
    UPPER('ELECTRONICS'),
    UPPER('GOOGLE REDESIGN'),
    UPPER('LIFESTYLE'),
    UPPER('NEST'),
    UPPER('NEW 2015 LOGO'),
    UPPER('NOTEBOOKS JOURNALS'),
    UPPER('OFFICE'),
    UPPER('SHOP BY BRAND'),
    UPPER('SMALL GOODS'),
    UPPER('STATIONERY'),
    UPPER('WEARABLES')
  ) AS categories
),
event_params AS (
  SELECT
    t."EVENT_TIMESTAMP",
    t."USER_PSEUDO_ID",
    t."EVENT_NAME",
    t."EVENT_DATE",
    MAX(CASE WHEN ep.value:"key"::STRING = 'page_location' THEN ep.value:"value":"string_value"::STRING END) AS "page_location",
    MAX(CASE WHEN ep.value:"key"::STRING = 'ga_session_id' THEN ep.value:"value":"int_value"::NUMBER END) AS "ga_session_id"
  FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" t,
  LATERAL FLATTEN(input => t."EVENT_PARAMS") ep
  WHERE t."EVENT_DATE" = '20210102'
    AND t."EVENT_NAME" = 'page_view'
  GROUP BY
    t."EVENT_TIMESTAMP",
    t."USER_PSEUDO_ID",
    t."EVENT_NAME",
    t."EVENT_DATE"
),
classified_events AS (
  SELECT
    ep.*,
    REGEXP_REPLACE(GET(PARSE_URL("page_location"), 'path')::STRING, '^/', '') AS path,
    SPLIT(REGEXP_REPLACE(GET(PARSE_URL("page_location"), 'path')::STRING, '^/', ''), '/') AS path_segments
  FROM event_params ep
),
classified_events_with_type AS (
  SELECT
    ce.*,
    ARRAY_SIZE(ce.path_segments) AS n_segments,
    ce.path_segments[ARRAY_SIZE(ce.path_segments)-1] AS last_segment,
    CASE
      WHEN POSITION('+' IN ce.path_segments[ARRAY_SIZE(ce.path_segments)-1]) > 0 THEN 'PDP'
      WHEN UPPER(REPLACE(ce.path_segments[ARRAY_SIZE(ce.path_segments)-1], '+', ' ')) IN (SELECT VALUE FROM TABLE(FLATTEN(input => categories.categories))) THEN 'PLP'
      ELSE 'Other'
    END AS page_type
  FROM classified_events ce
  CROSS JOIN categories
)
SELECT
  COUNT(*) AS "Total_PLP_Views",
  COUNT(CASE WHEN next_pdp_timestamp IS NOT NULL THEN 1 END) AS "PLP_to_PDP_Transitions",
  ROUND(COUNT(CASE WHEN next_pdp_timestamp IS NOT NULL THEN 1 END)::FLOAT / NULLIF(COUNT(*), 0) * 100, 4) AS "Transition_Percentage"
FROM (
  SELECT
    plp."ga_session_id",
    plp."USER_PSEUDO_ID",
    plp."EVENT_TIMESTAMP",
    MIN(pdp."EVENT_TIMESTAMP") AS next_pdp_timestamp
  FROM classified_events_with_type plp
  LEFT JOIN classified_events_with_type pdp
    ON plp."USER_PSEUDO_ID" = pdp."USER_PSEUDO_ID"
    AND plp."ga_session_id" = pdp."ga_session_id"
    AND pdp."EVENT_TIMESTAMP" > plp."EVENT_TIMESTAMP"
    AND pdp.page_type = 'PDP'
  WHERE plp.page_type = 'PLP'
  GROUP BY
    plp."ga_session_id",
    plp."USER_PSEUDO_ID",
    plp."EVENT_TIMESTAMP"
);