-- Task: Find out the total number of page views on January 2, 2021.

SELECT
  COUNT(*) AS total_page_views
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
WHERE
  event_name = 'page_view';