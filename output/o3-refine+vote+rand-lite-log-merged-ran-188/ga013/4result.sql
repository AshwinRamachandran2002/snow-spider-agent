WITH src AS (
  -- pull all events for the requested user & day
  SELECT
    -- grab the values of page_title and page_location that live inside event_params
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title'
      LIMIT 1)                                           AS page_title,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location'
      LIMIT 1)                                           AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE user_pseudo_id = '1402138.5184246691'
),
-- break the URL into path segments so we can test the PDP / PLP rules
paths AS (
  SELECT DISTINCT
    page_title,
    page_location,
    SPLIT(
      REGEXP_REPLACE(page_location, r'^https?://[^/]+/', ''),  -- drop protocol + domain
      '/'
    ) AS segments                                              -- array of path segments
  FROM src
)
SELECT DISTINCT
  CASE
    /* ---------- PDP : 5‑plus segments, 4th/5th is a category, last seg has '+' ---------- */
    WHEN ARRAY_LENGTH(segments) >= 5
         AND (
              LOWER(segments[OFFSET(3)]) IN (
                  'accessories','apparel','brands','campus+collection','drinkware',
                  'electronics','google+redesign','lifestyle','nest','new+2015+logo',
                  'notebooks+journals','office','shop+by+brand','small+goods',
                  'stationery','wearables')
           OR LOWER(segments[OFFSET(4)]) IN (
                  'accessories','apparel','brands','campus+collection','drinkware',
                  'electronics','google+redesign','lifestyle','nest','new+2015+logo',
                  'notebooks+journals','office','shop+by+brand','small+goods',
                  'stationery','wearables')
         )
         AND REGEXP_CONTAINS(segments[OFFSET(ARRAY_LENGTH(segments)-1)], r'\+')
         THEN 'PDP'

    /* ---------- PLP : 5‑plus segments, 4th/5th is a category, last seg has NO '+' ------- */
    WHEN ARRAY_LENGTH(segments) >= 5
         AND (
              LOWER(segments[OFFSET(3)]) IN (
                  'accessories','apparel','brands','campus+collection','drinkware',
                  'electronics','google+redesign','lifestyle','nest','new+2015+logo',
                  'notebooks+journals','office','shop+by+brand','small+goods',
                  'stationery','wearables')
           OR LOWER(segments[OFFSET(4)]) IN (
                  'accessories','apparel','brands','campus+collection','drinkware',
                  'electronics','google+redesign','lifestyle','nest','new+2015+logo',
                  'notebooks+journals','office','shop+by+brand','small+goods',
                  'stationery','wearables')
         )
         AND NOT REGEXP_CONTAINS(segments[OFFSET(ARRAY_LENGTH(segments)-1)], r'\+')
         THEN 'PLP'

    /* ---------- anything else : keep the human‑readable page title ---------------------- */
    ELSE page_title
  END AS page_name
FROM paths
WHERE page_title IS NOT NULL OR page_location IS NOT NULL
ORDER BY page_name;