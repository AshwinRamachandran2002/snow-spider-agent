-- Distinct pages visited by user 1402138.5184246691 on 2‑Jan‑2021
-- with refined Product‑Detail / Product‑Listing classification
WITH hits AS (
  SELECT
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'page_title')    AS page_title,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'page_location') AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE user_pseudo_id = '1402138.5184246691'
),
classified AS (
  SELECT DISTINCT
    COALESCE(page_title, '(not set)') AS page_name,
    CASE
      -- Product Detail Page (PDP)
      WHEN ARRAY_LENGTH(SPLIT(page_location, '/')) >= 5
           AND REGEXP_CONTAINS(page_location, r'/[^/]*\+[^/]*$')
           AND REGEXP_CONTAINS(
                 LOWER(page_location),
                 r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/')
      THEN 'PDP'

      -- Product Listing Page (PLP)
      WHEN ARRAY_LENGTH(SPLIT(page_location, '/')) >= 5
           AND NOT REGEXP_CONTAINS(page_location, r'/[^/]*\+[^/]*$')
           AND REGEXP_CONTAINS(
                 LOWER(page_location),
                 r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/')
      THEN 'PLP'

      ELSE 'OTHER'
    END AS page_type
  FROM hits
)
SELECT
  page_name,
  page_type
FROM classified
ORDER BY page_name;