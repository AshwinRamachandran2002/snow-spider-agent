-- pages visited by the required user on 2‑Jan‑2021,
-- replacing titles with “PDP” / “PLP” whenever the URL
-- matches the refined classification rules
WITH user_events AS (
  SELECT
    event_timestamp,
    ( SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location'
      LIMIT 1 ) AS page_url,
    ( SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title'
      LIMIT 1 ) AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE user_pseudo_id = '1402138.5184246691'
),
classified AS (
  SELECT
    event_timestamp,
    page_url,
    page_title,
    CASE
      WHEN page_url IS NOT NULL
           AND REGEXP_CONTAINS(LOWER(page_url), r'\+[^/]*$')                          -- “+” in last segment
           AND REGEXP_CONTAINS(LOWER(page_url),
                r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/')
        THEN 'PDP'
      WHEN page_url IS NOT NULL
           AND REGEXP_CONTAINS(LOWER(page_url),
                r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/')
           AND NOT REGEXP_CONTAINS(LOWER(page_url), r'\+[^/]*$')
        THEN 'PLP'
      ELSE NULL
    END AS page_type
  FROM user_events
)
SELECT DISTINCT
  COALESCE(page_type, page_title, page_url) AS visited_page
FROM classified
WHERE page_url IS NOT NULL
ORDER BY visited_page;