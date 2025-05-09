-- List every distinct page the user visited on 2021-01-02,
-- replacing the page name with “PDP” or “PLP” when the URL
-- matches the refined classification rules, otherwise
-- keeping the original page_title.
WITH page_views AS (
  SELECT
    pt.value.string_value AS page_title,
    pl.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t
  CROSS JOIN UNNEST(t.event_params) AS pt
  CROSS JOIN UNNEST(t.event_params) AS pl
  WHERE t.user_pseudo_id = '1402138.5184246691'
    AND t.event_name     = 'page_view'
    AND pt.key           = 'page_title'
    AND pl.key           = 'page_location'
)
SELECT DISTINCT
  CASE
    -- PDP: category keyword in URL + ‘+’ in last segment
    WHEN REGEXP_CONTAINS(
           LOWER(page_location),
           r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'
         )
         AND REGEXP_CONTAINS(REGEXP_EXTRACT(page_location, r'[^/]+$'), r'\+')
    THEN 'PDP'

    -- PLP: category keyword in URL, but no ‘+’ in last segment
    WHEN REGEXP_CONTAINS(
           LOWER(page_location),
           r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'
         )
    THEN 'PLP'

    -- Otherwise keep original page title
    ELSE page_title
  END AS page_name
FROM page_views
ORDER BY page_name;