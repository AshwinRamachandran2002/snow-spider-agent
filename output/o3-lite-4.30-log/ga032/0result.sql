/* Navigation flow for user 1362228.4966015575 on 2021‑01‑28 */
WITH base AS (
  -- one record per page_view with title and URL
  SELECT
    e.event_timestamp,
    MAX(IF(ep.key = 'page_title'   , ep.value.string_value, NULL)) AS page_title,
    MAX(IF(ep.key = 'page_location', ep.value.string_value, NULL)) AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128` AS e
  CROSS JOIN UNNEST(e.event_params) AS ep
  WHERE e.event_date     = '20210128'
    AND e.user_pseudo_id = '1362228.4966015575'
    AND e.event_name     = 'page_view'
  GROUP BY e.event_timestamp
),
typed AS (
  SELECT
    event_timestamp,
    page_title,
    LOWER(page_location)                                   AS page_location_lc,
    SPLIT(LOWER(page_location), '/')                       AS parts
  FROM base
),
classified AS (
  SELECT
    event_timestamp,
    CASE
      /* Product Detail Page (PDP) */
      WHEN ARRAY_LENGTH(parts) >= 5
           AND REGEXP_CONTAINS(parts[SAFE_OFFSET(ARRAY_LENGTH(parts)-1)], r'\+')
           AND (
                 REGEXP_CONTAINS(parts[SAFE_OFFSET(3)],
                     r'accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|'
                     r'lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|'
                     r'stationery|wearables')
              OR REGEXP_CONTAINS(parts[SAFE_OFFSET(4)],
                     r'accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|'
                     r'lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|'
                     r'stationery|wearables')
               )
      THEN 'PDP'

      /* Product Listing Page (PLP) */
      WHEN ARRAY_LENGTH(parts) >= 5
           AND NOT REGEXP_CONTAINS(parts[SAFE_OFFSET(ARRAY_LENGTH(parts)-1)], r'\+')
           AND (
                 REGEXP_CONTAINS(parts[SAFE_OFFSET(3)],
                     r'accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|'
                     r'lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|'
                     r'stationery|wearables')
              OR REGEXP_CONTAINS(parts[SAFE_OFFSET(4)],
                     r'accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|'
                     r'lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|'
                     r'stationery|wearables')
               )
      THEN 'PLP'

      /* Other pages keep their original title */
      ELSE page_title
    END AS label
  FROM typed
),
ordered AS (
  SELECT
    event_timestamp,
    label,
    LAG(label) OVER (ORDER BY event_timestamp) AS prev_label
  FROM classified
),
dedup AS (
  SELECT
    label,
    ROW_NUMBER() OVER (ORDER BY event_timestamp) AS seq
  FROM ordered
  WHERE prev_label IS NULL OR label <> prev_label
)
SELECT STRING_AGG(label, ' >> ' ORDER BY seq) AS navigation_flow
FROM dedup;