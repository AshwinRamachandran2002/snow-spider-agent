/* navigation flow for user 1362228.4966015575 on 28‑Jan‑2021 (page_view only) */
WITH page_views AS (
  SELECT
    event_timestamp,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title')     AS page_title,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location')  AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX = '20210128'
    AND user_pseudo_id = '1362228.4966015575'
    AND event_name     = 'page_view'
),
classified AS (
  SELECT
    event_timestamp,
    page_title,
    page_location,
    /* classify each hit as PDP / PLP / page_title */
    CASE
      WHEN page_location IS NULL THEN page_title
      ELSE (
        /* parts[] is url segments split on “/” */
        SELECT
          CASE
            WHEN
              ARRAY_LENGTH(parts) >= 5
              AND (
                   REGEXP_CONTAINS( LOWER(parts[OFFSET(3)]), r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
                OR REGEXP_CONTAINS( LOWER(parts[OFFSET(4)]), r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
                  )
              AND STRPOS(parts[ORDINAL(ARRAY_LENGTH(parts))], '+') > 0
            THEN 'PDP'
            WHEN
              ARRAY_LENGTH(parts) >= 5
              AND (
                   REGEXP_CONTAINS( LOWER(parts[OFFSET(3)]), r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
                OR REGEXP_CONTAINS( LOWER(parts[OFFSET(4)]), r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
                  )
              AND STRPOS(parts[ORDINAL(ARRAY_LENGTH(parts))], '+') = 0
            THEN 'PLP'
            ELSE page_title
          END
        FROM (SELECT SPLIT(page_location,'/') AS parts)
      )
    END AS page_type
  FROM page_views
),
steps AS (
  SELECT
    *,
    CASE
      WHEN LAG(page_type) OVER (ORDER BY event_timestamp) = page_type
      THEN 0 ELSE 1
    END AS is_new
  FROM classified
),
grouped AS (
  SELECT
    *,
    SUM(is_new) OVER (ORDER BY event_timestamp) AS grp_id
  FROM steps
),
distinct_steps AS (
  SELECT
    MIN(event_timestamp) AS first_ts,
    page_type
  FROM grouped
  GROUP BY grp_id, page_type
  ORDER BY first_ts
)
SELECT STRING_AGG(page_type, ' >> ' ORDER BY first_ts) AS navigation_flow
FROM distinct_steps;