/* Navigation flow (page_view only) for one user on 2021-01-28  */
WITH page_views AS (
  /* Pull one row per page_view with its URL and title  */
  SELECT
    event_timestamp,
    (
      SELECT MAX(p.value.string_value)
      FROM   UNNEST(event_params) AS p
      WHERE  p.key = 'page_location'
    ) AS page_location,
    (
      SELECT MAX(p.value.string_value)
      FROM   UNNEST(event_params) AS p
      WHERE  p.key = 'page_title'
    ) AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE user_pseudo_id = '1362228.4966015575'
    AND event_name     = 'page_view'
),
/* Convert each URL to PDP / PLP when rules match, else keep page_title */
classified AS (
  SELECT
    event_timestamp,
    CASE
        /* -------- PDP -------- */
        WHEN ARRAY_LENGTH(SPLIT(REGEXP_REPLACE(page_location,r'^https?://[^/]+/',''),'/')) >= 5
             AND REGEXP_CONTAINS(SPLIT(page_location,'/')[-1], r'\+')
             AND (
                   REGEXP_CONTAINS(LOWER(SPLIT(page_location,'/')[OFFSET(3)]),
                                   r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
                OR REGEXP_CONTAINS(LOWER(SPLIT(page_location,'/')[OFFSET(4)]),
                                   r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
                 )
        THEN 'PDP'

        /* -------- PLP -------- */
        WHEN ARRAY_LENGTH(SPLIT(REGEXP_REPLACE(page_location,r'^https?://[^/]+/',''),'/')) >= 5
             AND NOT REGEXP_CONTAINS(SPLIT(page_location,'/')[OFFSET(3)], r'\+')
             AND NOT REGEXP_CONTAINS(SPLIT(page_location,'/')[OFFSET(4)], r'\+')
             AND (
                   REGEXP_CONTAINS(LOWER(SPLIT(page_location,'/')[OFFSET(3)]),
                                   r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
                OR REGEXP_CONTAINS(LOWER(SPLIT(page_location,'/')[OFFSET(4)]),
                                   r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
                 )
        THEN 'PLP'

        /* -------- Neither PDP nor PLP -------- */
        ELSE page_title
    END AS page_id
  FROM page_views
),
/* Flag first appearance of each consecutive page_id */
dedup AS (
  SELECT
    event_timestamp,
    page_id,
    CASE WHEN LAG(page_id) OVER (ORDER BY event_timestamp) = page_id
         THEN 0 ELSE 1 END AS new_step
  FROM classified
),
/* Give the distinct steps running numbers */
numbered AS (
  SELECT
    event_timestamp,
    page_id,
    SUM(new_step) OVER (ORDER BY event_timestamp) AS grp
  FROM dedup
)
/* Stitch the steps together with ">>" */
SELECT
  STRING_AGG(page_id, '>>' ORDER BY grp) AS navigation_flow
FROM (
  SELECT DISTINCT grp, page_id
  FROM   numbered
  ORDER  BY grp
);