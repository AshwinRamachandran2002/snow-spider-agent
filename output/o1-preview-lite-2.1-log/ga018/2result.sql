WITH events AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id' LIMIT 1) AS session_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location' LIMIT 1) AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
processed_events AS (
  SELECT
    user_pseudo_id,
    session_id,
    page_location,
    SPLIT(page_location, '/') AS segments,
    ARRAY_LENGTH(SPLIT(page_location, '/')) AS num_segments,
    SPLIT(LOWER(REPLACE(page_location, '+', ' ')), '/') AS clean_segments
  FROM events
),
classified_events AS (
  SELECT
    user_pseudo_id,
    session_id,
    CASE
      WHEN num_segments >= 5
        AND clean_segments[SAFE_OFFSET(num_segments - 1)] IN UNNEST([
          'accessories','apparel','brands','campus collection','drinkware','electronics','google redesign',
          'lifestyle','nest','new 2015 logo','notebooks journals','office','shop by brand','small goods',
          'stationery','wearables'
        ])
        THEN 'PLP'
      WHEN num_segments >= 5
        AND clean_segments[SAFE_OFFSET(num_segments - 1)] NOT IN UNNEST([
          'accessories','apparel','brands','campus collection','drinkware','electronics','google redesign',
          'lifestyle','nest','new 2015 logo','notebooks journals','office','shop by brand','small goods',
          'stationery','wearables'
        ])
        AND (
          clean_segments[SAFE_OFFSET(3)] IN UNNEST([
            'accessories','apparel','brands','campus collection','drinkware','electronics','google redesign',
            'lifestyle','nest','new 2015 logo','notebooks journals','office','shop by brand','small goods',
            'stationery','wearables'
          ])
          OR clean_segments[SAFE_OFFSET(4)] IN UNNEST([
            'accessories','apparel','brands','campus collection','drinkware','electronics','google redesign',
            'lifestyle','nest','new 2015 logo','notebooks journals','office','shop by brand','small goods',
            'stationery','wearables'
          ])
        )
        THEN 'PDP'
      ELSE 'Other'
    END AS page_type
  FROM processed_events
),
sessions AS (
  SELECT
    user_pseudo_id,
    session_id,
    MAX(IF(page_type = 'PLP', 1, 0)) AS has_plp,
    MAX(IF(page_type = 'PDP', 1, 0)) AS has_pdp
  FROM classified_events
  WHERE page_type IN ('PLP', 'PDP')
  GROUP BY user_pseudo_id, session_id
)
SELECT
  ROUND(SAFE_DIVIDE(SUM(IF(has_plp = 1 AND has_pdp = 1, 1, 0)), NULLIF(SUM(IF(has_plp = 1, 1, 0)), 0)) * 100, 4) AS Percentage
FROM sessions;