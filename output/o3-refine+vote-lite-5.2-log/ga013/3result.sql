/*  Pages visited by user 1402138.5184246691 on 2‑Jan‑2021
    – page titles are kept unless the URL matches the refined rules
      for a Product Listing Page (PLP) or Product Detail Page (PDP);
      in those cases the returned “name” is simply ‘PLP’ or ‘PDP’. */
WITH page_views AS (          -- grab every page_view for the user on 2021‑01‑02
  SELECT
    event_timestamp,
    MAX(IF(p.key = 'page_title'   , p.value.string_value, NULL)) AS page_title,
    MAX(IF(p.key = 'page_location', p.value.string_value, NULL)) AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  CROSS JOIN UNNEST(event_params) AS p
  WHERE _TABLE_SUFFIX      = '20210102'               --  2‑Jan‑2021
    AND user_pseudo_id     = '1402138.5184246691'
    AND event_name         = 'page_view'
  GROUP BY event_timestamp
),
classified AS (              -- decide whether the URL is a PDP or a PLP
  SELECT
    event_timestamp,
    page_title,
    page_location,
    CASE
      /* helper regex with allowed category names (case‑insensitive) */
      WHEN ARRAY_LENGTH(SPLIT(page_location, '/')) >= 5
           AND (
                 REGEXP_CONTAINS(LOWER(SPLIT(page_location, '/')[SAFE_OFFSET(3)]),
                                 r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
              OR REGEXP_CONTAINS(LOWER(SPLIT(page_location, '/')[SAFE_OFFSET(4)]),
                                 r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
               )
           AND REGEXP_CONTAINS(                            -- ‘+’ in the last segment ⇒ PDP
                 SPLIT(page_location, '/')[OFFSET(ARRAY_LENGTH(SPLIT(page_location, '/'))-1)],
                 r'\+'
               )
        THEN 'PDP'

      WHEN ARRAY_LENGTH(SPLIT(page_location, '/')) >= 5
           AND (
                 REGEXP_CONTAINS(LOWER(SPLIT(page_location, '/')[SAFE_OFFSET(3)]),
                                 r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
              OR REGEXP_CONTAINS(LOWER(SPLIT(page_location, '/')[SAFE_OFFSET(4)]),
                                 r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
               )
           AND NOT REGEXP_CONTAINS(SPLIT(page_location, '/')[SAFE_OFFSET(3)], r'\+')
           AND NOT REGEXP_CONTAINS(SPLIT(page_location, '/')[SAFE_OFFSET(4)], r'\+')
        THEN 'PLP'
      ELSE NULL
    END AS page_type
  FROM page_views
),
ordered_pages AS (           -- collapse duplicates & keep visit order
  SELECT
    COALESCE(page_type, page_title) AS page_name,
    MIN(event_timestamp)           AS first_seen
  FROM classified
  GROUP BY page_name
)
SELECT page_name
FROM ordered_pages
ORDER BY first_seen;