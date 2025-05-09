WITH base AS (
  -- 1. Pull the URL and title for every event of the target user on 2021‑01‑02
  SELECT
    event_timestamp,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location') AS page_location,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title')    AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE user_pseudo_id = '1402138.5184246691'
),
/* 2. List of merchandising categories to recognise in the URL */
categories AS (
  SELECT ARRAY<STRING>[
    'accessories','apparel','brands','campus+collection','drinkware','electronics',
    'google+redesign','lifestyle','nest','new+2015+logo','notebooks+journals',
    'office','shop+by+brand','small+goods','stationery','wearables'
  ] AS cat_list
),
/* 3. Classify every visited URL as PDP / PLP (or keep original page title) */
classified AS (
  SELECT
    b.event_timestamp,
    CASE
      -- Apply the PLP / PDP rules only when URL fits the category pattern
      WHEN b.page_location IS NOT NULL
           AND ARRAY_LENGTH(SPLIT(b.page_location, '/')) >= 5
           AND (
                 LOWER(SPLIT(b.page_location, '/')[SAFE_OFFSET(3)]) IN UNNEST(c.cat_list)
              OR LOWER(SPLIT(b.page_location, '/')[SAFE_OFFSET(4)]) IN UNNEST(c.cat_list)
               )
      THEN CASE
             -- PDP: “+” in the last segment
             WHEN REGEXP_CONTAINS(
                    SPLIT(b.page_location, '/')
                    [SAFE_OFFSET(ARRAY_LENGTH(SPLIT(b.page_location, '/')) - 1)],
                    r'\+')
                  THEN 'PDP'
             -- Otherwise PLP
             ELSE 'PLP'
           END
      -- Non‑matching URLs keep the original page title
      ELSE b.page_title
    END AS page_name
  FROM base b
  CROSS JOIN categories c
),
/* 4. Keep one record per distinct page visited (timestamp kept for ordering) */
dedup AS (
  SELECT
    page_name,
    MIN(event_timestamp) AS first_seen_ts
  FROM classified
  GROUP BY page_name
)
SELECT
  page_name
FROM dedup
ORDER BY first_seen_ts;