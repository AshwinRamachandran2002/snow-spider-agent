-- Percentage of Product Detail Page (PDP) views on 2021-01-02
WITH page_views AS (
  SELECT
    ep.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t,
       UNNEST(t.event_params) AS ep
  WHERE t.event_name = 'page_view'
    AND ep.key = 'page_location'
),
classified AS (
  SELECT
    page_location,
    -- PDP definition
    (
      ARRAY_LENGTH(SPLIT(page_location, '/')) >= 5                                             -- at least 5 segments
      AND REGEXP_CONTAINS(page_location, r'\+')                                                -- “+” in the last segment
      AND REGEXP_CONTAINS(LOWER(page_location),                                                -- category keyword present
            r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
    ) AS is_pdp
  FROM page_views
)
SELECT
  COUNTIF(is_pdp)                    AS pdp_page_views,
  COUNT(*)                           AS total_page_views,
  ROUND(100 * COUNTIF(is_pdp) / COUNT(*), 2) AS pdp_percentage
FROM classified;