/*  Pages visited by user 1402138.5184246691 on 02-Jan-2021.
    The page title is replaced by “PDP” or “PLP” whenever the URL
    matches the business rules supplied in the prompt.            */
WITH pages AS (     -- pull raw URL & title for every hit
  SELECT
    event_timestamp,
    MAX(CASE WHEN ep.key = 'page_location' THEN ep.value.string_value END) AS page_location,
    MAX(CASE WHEN ep.key = 'page_title'    THEN ep.value.string_value END) AS page_title
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`,
        UNNEST(event_params) AS ep
  WHERE user_pseudo_id = '1402138.5184246691'
  GROUP BY event_timestamp
),

classified AS (     -- classify each URL as PDP / PLP / OTHER
  SELECT
    event_timestamp,
    page_title,
    page_location,

    /* split URL once so we can reuse the parts */
    SPLIT(REGEXP_REPLACE(page_location, r'^https?://', ''), '/')                          AS segments,
    SPLIT(REGEXP_REPLACE(page_location, r'^https?://', ''), '/')[SAFE_OFFSET(3)]          AS seg4,
    SPLIT(REGEXP_REPLACE(page_location, r'^https?://', ''), '/')[SAFE_OFFSET(4)]          AS seg5,
    SPLIT(REGEXP_REPLACE(page_location, r'^https?://', ''), '/')
      [ORDINAL(ARRAY_LENGTH(SPLIT(REGEXP_REPLACE(page_location, r'^https?://', ''), '/')))] AS last_seg

  FROM pages
),

labeled AS (
  SELECT
    event_timestamp,
    page_title,
    page_location,

    CASE
      WHEN page_location IS NULL OR page_location = '' THEN 'OTHER'

      /* ---------- PDP ---------- */
      WHEN ARRAY_LENGTH(segments) >= 5
           AND REGEXP_CONTAINS(last_seg, r'\+')
           AND (
                 REGEXP_CONTAINS(LOWER(COALESCE(seg4, '')), r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
              OR REGEXP_CONTAINS(LOWER(COALESCE(seg5, '')), r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
               )
      THEN 'PDP'

      /* ---------- PLP ---------- */
      WHEN ARRAY_LENGTH(segments) >= 5
           AND NOT REGEXP_CONTAINS(COALESCE(seg4, ''), r'\+')
           AND NOT REGEXP_CONTAINS(COALESCE(seg5, ''), r'\+')
           AND (
                 REGEXP_CONTAINS(LOWER(COALESCE(seg4, '')), r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
              OR REGEXP_CONTAINS(LOWER(COALESCE(seg5, '')), r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
               )
      THEN 'PLP'

      ELSE 'OTHER'
    END AS page_class
  FROM classified
)

SELECT
  event_timestamp,
  CASE WHEN page_class IN ('PDP','PLP') THEN page_class ELSE page_title END AS page_name
FROM labeled
ORDER BY event_timestamp;