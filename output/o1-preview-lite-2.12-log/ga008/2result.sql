SELECT
  FORMAT_DATE('%Y-%m-%d', PARSE_DATE('%Y%m%d', event_date)) AS Date,
  SUM(page_views_per_user) AS Total_Page_Views,
  ROUND(AVG(page_views_per_user), 4) AS Average_Page_Views_Per_User
FROM (
  SELECT
    event_date,
    user_pseudo_id,
    COUNTIF(event_name = 'page_view') AS page_views_per_user
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND user_pseudo_id IN (
      SELECT DISTINCT user_pseudo_id
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
      WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
        AND event_name = 'purchase'
    )
  GROUP BY event_date, user_pseudo_id
)
GROUP BY Date
ORDER BY Date;