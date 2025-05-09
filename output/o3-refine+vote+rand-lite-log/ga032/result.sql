WITH page_views AS (
  SELECT
    event_timestamp,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title')     AS page_title,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location')  AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE event_date      = '20210128'
    AND event_name      = 'page_view'
    AND user_pseudo_id  = '1362228.4966015575'
),
classified AS (
  SELECT
    event_timestamp,
    page_title,
    page_location,
    CASE
      /* PDP  = category path present AND last segment contains '+' */
      WHEN REGEXP_CONTAINS(
             page_location,
             r'(?i)/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/'
           )
       AND REGEXP_CONTAINS(page_location, r'\+[^/]*$')
      THEN 'PDP'

      /* PLP = category path present BUT last segment *does not* contain '+' */
      WHEN REGEXP_CONTAINS(
             page_location,
             r'(?i)/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)/'
           )
       AND NOT REGEXP_CONTAINS(page_location, r'\+[^/]*$')
      THEN 'PLP'

      /* anything else keeps its page title */
      ELSE page_title
    END                                           AS step_name
  FROM page_views
),
dedup AS (
  /* keep only the first occurrence when consecutive pages are the same */
  SELECT *
  FROM (
    SELECT
      *,
      LAG(step_name) OVER (ORDER BY event_timestamp) AS prev_step
    FROM classified
  )
  WHERE step_name IS NOT NULL
    AND (prev_step IS NULL OR prev_step <> step_name)
)
SELECT
  STRING_AGG(step_name, ' >> ' ORDER BY event_timestamp) AS navigation_flow
FROM dedup;