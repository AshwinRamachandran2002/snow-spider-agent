WITH category_names AS (
  SELECT * FROM UNNEST([
    'Accessories',
    'Apparel',
    'Brands',
    'Campus+Collection',
    'Drinkware',
    'Electronics',
    'Google+Redesign',
    'Lifestyle',
    'Nest',
    'New+2015+Logo',
    'Notebooks+Journals',
    'Office',
    'Shop+by+Brand',
    'Small+Goods',
    'Stationery',
    'Wearables'
  ]) AS category_name
),
user_page_views AS (
  SELECT
    TIMESTAMP_MICROS(event_timestamp) AS event_time,
    IFNULL(
      (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'page_title'),
      'No Title'
    ) AS page_title,
    IFNULL(
      (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'page_location'),
      'No Location'
    ) AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE user_pseudo_id = '1362228.4966015575' AND event_name = 'page_view'
),
classified_pages AS (
  SELECT
    event_time,
    page_title,
    page_location,
    CASE
      WHEN
        ARRAY_LENGTH(SPLIT(page_location, '/')) >= 6
        AND (
          SPLIT(page_location, '/')[OFFSET(3)] IN UNNEST((SELECT ARRAY_AGG(category_name) FROM category_names))
          OR SPLIT(page_location, '/')[OFFSET(4)] IN UNNEST((SELECT ARRAY_AGG(category_name) FROM category_names))
        )
        AND NOT (
          INSTR(SPLIT(page_location, '/')[OFFSET(3)], '+') > 0
          OR INSTR(SPLIT(page_location, '/')[OFFSET(4)], '+') > 0
        )
      THEN 'PLP'
      WHEN
        ARRAY_LENGTH(SPLIT(page_location, '/')) >= 6
        AND (
          SPLIT(page_location, '/')[OFFSET(3)] IN UNNEST((SELECT ARRAY_AGG(category_name) FROM category_names))
          OR SPLIT(page_location, '/')[OFFSET(4)] IN UNNEST((SELECT ARRAY_AGG(category_name) FROM category_names))
        )
        AND (
          INSTR(SPLIT(page_location, '/')[OFFSET(3)], '+') > 0
          OR INSTR(SPLIT(page_location, '/')[OFFSET(4)], '+') > 0
        )
      THEN 'PDP'
      ELSE page_title
    END AS classified_page_title
  FROM user_page_views
),
deduped_pages AS (
  SELECT
    event_time,
    classified_page_title,
    ROW_NUMBER() OVER (ORDER BY event_time) AS rn
  FROM classified_pages
),
final_sequence AS (
  SELECT
    classified_page_title,
    rn
  FROM (
    SELECT
      classified_page_title,
      rn,
      LAG(classified_page_title) OVER (ORDER BY rn) AS prev_title
    FROM deduped_pages
  )
  WHERE classified_page_title != prev_title OR prev_title IS NULL
)
SELECT STRING_AGG(classified_page_title, ' >> ' ORDER BY rn) AS Sequence_of_Pages
FROM final_sequence;