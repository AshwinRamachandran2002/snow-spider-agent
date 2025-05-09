/*  PLP → PDP transition rate for 2-Jan-2021  */

WITH base AS (   -- grab every 2-Jan-2021 page_view with its session id and URL
  SELECT
    event_timestamp,
    ( SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id')          AS session_id,
    ( SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location')          AS url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
parts AS (       -- strip domain and split the path into its segments
  SELECT
    *,
    SPLIT(REGEXP_EXTRACT(url, r'https?://[^/]+/(.*)'), '/') AS seg
  FROM base
  WHERE url IS NOT NULL AND session_id IS NOT NULL
),
classified AS (  -- flag each row as PLP or PDP according to the refined rules
  SELECT
    *,
    CASE
      WHEN ARRAY_LENGTH(SPLIT(url,'/')) >= 5
           AND NOT REGEXP_CONTAINS(seg[SAFE_OFFSET(ARRAY_LENGTH(seg)-1)], r'\+')
           AND ( LOWER(seg[OFFSET(0)]) IN ('accessories','apparel','brands','campus+collection',
                                           'drinkware','electronics','google+redesign','lifestyle',
                                           'nest','new+2015+logo','notebooks+journals','office',
                                           'shop+by+brand','small+goods','stationery','wearables')
              OR LOWER(seg[SAFE_OFFSET(1)]) IN ('accessories','apparel','brands','campus+collection',
                                               'drinkware','electronics','google+redesign','lifestyle',
                                               'nest','new+2015+logo','notebooks+journals','office',
                                               'shop+by+brand','small+goods','stationery','wearables') )
      THEN 1 ELSE 0 END                                            AS is_plp,

    CASE
      WHEN ARRAY_LENGTH(SPLIT(url,'/')) >= 5
           AND REGEXP_CONTAINS(seg[SAFE_OFFSET(ARRAY_LENGTH(seg)-1)], r'\+')
           AND ( LOWER(seg[OFFSET(0)]) IN ('accessories','apparel','brands','campus+collection',
                                           'drinkware','electronics','google+redesign','lifestyle',
                                           'nest','new+2015+logo','notebooks+journals','office',
                                           'shop+by+brand','small+goods','stationery','wearables')
              OR LOWER(seg[SAFE_OFFSET(1)]) IN ('accessories','apparel','brands','campus+collection',
                                               'drinkware','electronics','google+redesign','lifestyle',
                                               'nest','new+2015+logo','notebooks+journals','office',
                                               'shop+by+brand','small+goods','stationery','wearables') )
      THEN 1 ELSE 0 END                                            AS is_pdp
  FROM parts
),
plp AS (         -- every PLP view
  SELECT event_timestamp, session_id
  FROM classified
  WHERE is_plp = 1
),
pdp AS (         -- every PDP view
  SELECT event_timestamp, session_id
  FROM classified
  WHERE is_pdp = 1
),
plp_flag AS (    -- for each PLP, did a PDP occur later in the same session?
  SELECT
    p.event_timestamp,
    p.session_id,
    EXISTS (
      SELECT 1
      FROM pdp d
      WHERE d.session_id = p.session_id
        AND d.event_timestamp > p.event_timestamp
    ) AS leads_to_pdp
  FROM plp p
)
SELECT
  COUNT(*)                                            AS total_plp_views,
  COUNTIF(leads_to_pdp)                               AS plp_views_leading_to_pdp,
  SAFE_DIVIDE(COUNTIF(leads_to_pdp), COUNT(*)) * 100  AS pct_plp_to_pdp
FROM plp_flag;