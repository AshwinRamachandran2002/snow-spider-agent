SELECT DISTINCT
  CASE
    WHEN ARRAY_LENGTH(SPLIT(REGEXP_REPLACE(loc,
                                           r'^https?://[^/]+', ''), '/')) >= 5
         AND REGEXP_CONTAINS(LOWER(loc),
              r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
         AND REGEXP_CONTAINS(loc, r'\+')
      THEN 'PDP'
    WHEN ARRAY_LENGTH(SPLIT(REGEXP_REPLACE(loc,
                                           r'^https?://[^/]+', ''), '/')) >= 5
         AND REGEXP_CONTAINS(LOWER(loc),
              r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
         AND NOT REGEXP_CONTAINS(loc, r'\+')
      THEN 'PLP'
    ELSE title
  END AS page_name
FROM (
  SELECT
    (SELECT value.string_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'page_location'
      LIMIT 1) AS loc,
    (SELECT value.string_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'page_title'
      LIMIT 1) AS title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_date     = '20210102'
    AND user_pseudo_id = '1402138.5184246691'
    AND event_name     = 'page_view'
)
ORDER BY page_name;