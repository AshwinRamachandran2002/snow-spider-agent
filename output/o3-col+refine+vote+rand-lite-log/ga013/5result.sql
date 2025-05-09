-- Pages visited by user 1402138.5184246691 on 2-Jan-2021, tagged as PDP / PLP / OTHER
WITH categories AS (
  SELECT [
    'accessories','apparel','brands','campus+collection','drinkware','electronics',
    'google+redesign','lifestyle','nest','new+2015+logo','notebooks+journals',
    'office','shop+by+brand','small+goods','stationery','wearables'
  ] AS cat_list
),
raw AS (   -- one row per page_view hit with its URL & title
  SELECT
    MAX(IF(ep.key = 'page_location', ep.value.string_value, NULL)) AS page_location,
    MAX(IF(ep.key = 'page_title',    ep.value.string_value, NULL)) AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` t
  CROSS JOIN UNNEST(t.event_params) AS ep
  WHERE t.user_pseudo_id = '1402138.5184246691'
    AND t.event_name     = 'page_view'
    AND t.event_date     = '20210102'
  GROUP BY t.event_timestamp
),
classified AS (   -- apply PLP / PDP rules
  SELECT
    COALESCE(page_title, page_location) AS page_name,
    CASE
      WHEN ARRAY_LENGTH(parts) >= 5
           AND (LOWER(parts[SAFE_OFFSET(3)]) IN UNNEST(cat_list)
                OR LOWER(parts[SAFE_OFFSET(4)]) IN UNNEST(cat_list))
           AND STRPOS(parts[ORDINAL(ARRAY_LENGTH(parts))], '+') > 0
        THEN 'PDP'
      WHEN ARRAY_LENGTH(parts) >= 5
           AND (LOWER(parts[SAFE_OFFSET(3)]) IN UNNEST(cat_list)
                OR LOWER(parts[SAFE_OFFSET(4)]) IN UNNEST(cat_list))
           AND STRPOS(parts[ORDINAL(ARRAY_LENGTH(parts))], '+') = 0
        THEN 'PLP'
      ELSE 'OTHER'
    END AS page_type
  FROM raw, categories,
  UNNEST([STRUCT(SPLIT(page_location, '/') AS parts)])
)
SELECT DISTINCT
  page_name,
  page_type
FROM classified
ORDER BY page_name;