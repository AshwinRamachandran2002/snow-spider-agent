WITH user_pages AS (
  /* 1.  All page_view events for the requested user on 2‑Jan‑2021            */
  SELECT
    event_timestamp,
    MAX(IF(p.key = 'page_title'   , p.value.string_value, NULL)) AS page_title,
    MAX(IF(p.key = 'page_location', p.value.string_value, NULL)) AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`,
       UNNEST(event_params) AS p
  WHERE user_pseudo_id = '1402138.5184246691'
    AND event_name     = 'page_view'
  GROUP BY event_timestamp
),
segments AS (
  /* 2.  Split the URL into its path segments                                */
  SELECT
    *,
    SPLIT(
      REGEXP_REPLACE(page_location, r'^https?://[^/]+/', ''),  -- remove domain
      '/'
    ) AS seg
  FROM user_pages
),
classified AS (
  /* 3.  Classify each URL as PDP / PLP when it matches the rules            */
  SELECT
    event_timestamp,
    page_title,
    CASE
      /* ---------- PDP ---------------------------------------------------- */
      WHEN ARRAY_LENGTH(seg) >= 5
           AND ( REGEXP_CONTAINS(
                    LOWER(IFNULL(seg[SAFE_OFFSET(3)],'')),
                    r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'
                 )
              OR REGEXP_CONTAINS(
                    LOWER(IFNULL(seg[SAFE_OFFSET(4)],'')),
                    r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'
                 )
             )
           AND REGEXP_CONTAINS(LOWER(seg[ORDINAL(ARRAY_LENGTH(seg))]), r'\+')
        THEN 'PDP'

      /* ---------- PLP ---------------------------------------------------- */
      WHEN ARRAY_LENGTH(seg) >= 5
           AND ( REGEXP_CONTAINS(
                    LOWER(IFNULL(seg[SAFE_OFFSET(3)],'')),
                    r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'
                 )
              OR REGEXP_CONTAINS(
                    LOWER(IFNULL(seg[SAFE_OFFSET(4)],'')),
                    r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)'
                 )
             )
           AND NOT REGEXP_CONTAINS(LOWER(IFNULL(seg[SAFE_OFFSET(3)],'')), r'\+')
           AND NOT REGEXP_CONTAINS(LOWER(IFNULL(seg[SAFE_OFFSET(4)],'')), r'\+')
        THEN 'PLP'

      /* ---------- anything else: keep original title --------------------- */
      ELSE page_title
    END AS page_name
  FROM segments
)
SELECT DISTINCT page_name
FROM   classified
ORDER  BY page_name;