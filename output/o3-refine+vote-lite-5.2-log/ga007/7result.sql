WITH pageviews AS (
  -- 1. keep only the page‑view events of 2 Jan 2021 and pull the URL
  SELECT
    ( SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location'
      LIMIT 1 ) AS page_url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
), parsed AS (
  -- 2. remove protocol and split the url into path segments
  SELECT
    page_url,
    SPLIT( REGEXP_REPLACE(page_url, r'^https?://', ''), '/' )             AS segments
  FROM pageviews
), classified AS (
  -- 3. pull the parts we need for the PDP rules
  SELECT
    page_url,
    segments,
    ARRAY_LENGTH(segments)                                   AS num_segments,
    segments[SAFE_OFFSET(ARRAY_LENGTH(segments)-1)]          AS last_segment,
    segments[SAFE_OFFSET(3)]                                 AS segment4,     -- 4‑th segment (0‑based index 3)
    segments[SAFE_OFFSET(4)]                                 AS segment5      -- 5‑th segment (0‑based index 4)
  FROM parsed
), flags AS (
  -- 4. apply the PDP definition
  SELECT
    *,
    CASE
      WHEN num_segments >= 5
           AND STRPOS(last_segment, '+') > 0
           AND (
                 LOWER(REPLACE(segment4, '+', ' ')) IN UNNEST([
                   'accessories','apparel','brands','campus collection','drinkware','electronics',
                   'google redesign','lifestyle','nest','new 2015 logo','notebooks journals',
                   'office','shop by brand','small goods','stationery','wearables'])
              OR LOWER(REPLACE(segment5, '+', ' ')) IN UNNEST([
                   'accessories','apparel','brands','campus collection','drinkware','electronics',
                   'google redesign','lifestyle','nest','new 2015 logo','notebooks journals',
                   'office','shop by brand','small goods','stationery','wearables'])
           )
      THEN TRUE ELSE FALSE
    END AS is_pdp
  FROM classified
)
-- 5. percentage of PDP page‑views
SELECT
  ROUND( SAFE_DIVIDE( SUM(CASE WHEN is_pdp THEN 1 ELSE 0 END)
                      ,COUNT(*) ) * 100 , 4) AS percentage_pdp_pageviews
FROM flags;