/*  PLP ➜ PDP transition rate for 2-Jan-2021  */
WITH page_views AS (
  --Pull the essential identifiers and the URL for every page_view event
  SELECT
    user_pseudo_id,
    (SELECT value.int_value
       FROM UNNEST(event_params)
       WHERE key = 'ga_session_id')        AS ga_session_id,
    event_timestamp,
    (SELECT value.string_value
       FROM UNNEST(event_params)
       WHERE key = 'page_location')        AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
classified AS (
  --Classify every page_view URL as PLP, PDP or OTHER using the refined rules
  SELECT
    pv.*,
    CASE
      WHEN REGEXP_CONTAINS(
             page_location,
             r'(?i)/(Accessories|Apparel|Brands|Campus\+Collection|Drinkware|Electronics|Google\+Redesign|Lifestyle|Nest|New\+2015\+Logo|Notebooks\+Journals|Office|Shop\+by\+Brand|Small\+Goods|Stationery|Wearables)/')
      THEN
        CASE
          WHEN REGEXP_CONTAINS(page_location, r'\+[^/]*$') THEN 'PDP'
          ELSE 'PLP'
        END
      ELSE 'OTHER'
    END AS page_type
  FROM page_views AS pv
),
plp AS (
  --Keep only PLP views
  SELECT *
  FROM classified
  WHERE page_type = 'PLP'
),
plp_flagged AS (
  --For each PLP, flag if a later PDP occurs in the same (user, session)
  SELECT
    p.*,
    EXISTS (
      SELECT 1
      FROM classified AS d
      WHERE d.page_type      = 'PDP'
        AND d.user_pseudo_id = p.user_pseudo_id
        AND d.ga_session_id  = p.ga_session_id
        AND d.event_timestamp > p.event_timestamp
    ) AS led_to_pdp
  FROM plp AS p
)
--Aggregate the final counts and compute the percentage
SELECT
  COUNT(*)                                        AS total_plp_views,
  SUM(CASE WHEN led_to_pdp THEN 1 ELSE 0 END)     AS plp_with_pdp,
  ROUND(100 * SUM(CASE WHEN led_to_pdp THEN 1 ELSE 0 END)
/ COUNT(*), 2)                                   AS pct_plp_to_pdp
FROM plp_flagged;