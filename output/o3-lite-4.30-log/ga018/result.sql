WITH page_views AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    event_timestamp,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_date = '20210102'
    AND event_name = 'page_view'
),
classified AS (
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp,
    CASE
      WHEN REGEXP_CONTAINS(LOWER(url),
           r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
      THEN CASE
             WHEN REGEXP_CONTAINS(LOWER(REGEXP_EXTRACT(url, r'/([^/?#]+)$')), r'\+') THEN 'PDP'
             ELSE 'PLP'
           END
      ELSE 'OTHER'
    END AS page_type
  FROM page_views
),
plp AS (
  SELECT user_pseudo_id, session_id, event_timestamp
  FROM classified
  WHERE page_type = 'PLP'
),
pdp AS (
  SELECT user_pseudo_id, session_id, event_timestamp
  FROM classified
  WHERE page_type = 'PDP'
),
joined AS (
  SELECT
    plp.user_pseudo_id,
    plp.session_id,
    plp.event_timestamp AS plp_ts,
    MIN(pdp.event_timestamp) AS next_pdp_ts
  FROM plp
  LEFT JOIN pdp
    ON plp.user_pseudo_id = pdp.user_pseudo_id
   AND plp.session_id     = pdp.session_id
   AND pdp.event_timestamp > plp.event_timestamp
  GROUP BY plp.user_pseudo_id, plp.session_id, plp.event_timestamp
)
SELECT
  COUNT(*)                                          AS plp_views,
  COUNTIF(next_pdp_ts IS NOT NULL)                  AS pdp_transitions,
  ROUND(SAFE_DIVIDE(COUNTIF(next_pdp_ts IS NOT NULL), COUNT(*)) * 100, 4)
                                                    AS transition_percentage
FROM joined;