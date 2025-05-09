-- Description: List every page visited by the user on 2021-01-02
-- and classify each page as PDP, PLP, or Other.
WITH raw AS (
  SELECT
    MAX(CASE WHEN ep.key = 'page_title'    THEN ep.value.string_value END) AS page_title,
    MAX(CASE WHEN ep.key = 'page_location' THEN ep.value.string_value END) AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t
  CROSS JOIN UNNEST(t.event_params) AS ep
  WHERE t.user_pseudo_id = '1402138.5184246691'
    AND t.event_name     = 'page_view'
  GROUP BY t.event_timestamp            -- one row per screen view
),
classified AS (
  SELECT
    page_title,
    CASE
      -- PDP = category URL that ends with a segment containing “+”
      WHEN REGEXP_CONTAINS(
             LOWER(SPLIT(page_location,'/')[SAFE_ORDINAL(ARRAY_LENGTH(SPLIT(page_location,'/')))]),
             r'\+')
       AND REGEXP_CONTAINS(
             LOWER(page_location),
             r'accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables')
        THEN 'PDP'

      -- PLP = category URL without “+” in last segment
      WHEN REGEXP_CONTAINS(
             LOWER(page_location),
             r'accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables')
        THEN 'PLP'

      ELSE 'Other'
    END AS page_type
  FROM raw
)
SELECT DISTINCT
  page_title AS page_name,
  page_type
FROM classified
ORDER BY page_name;