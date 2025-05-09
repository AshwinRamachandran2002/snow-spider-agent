SELECT
  ROUND(AVG_purchasers - AVG_non_purchasers, 4) AS Average_Difference_in_Pageviews
FROM
  (
    SELECT AVG(pageview_count) AS AVG_purchasers
    FROM (
      SELECT user_pseudo_id, COUNT(*) AS pageview_count
      FROM `bigquery-public-data`.`ga4_obfuscated_sample_ecommerce`.`events_*`
      WHERE event_name = 'page_view'
        AND event_date BETWEEN '20201201' AND '20201231'
        AND user_pseudo_id IN (
          SELECT DISTINCT user_pseudo_id
          FROM `bigquery-public-data`.`ga4_obfuscated_sample_ecommerce`.`events_*`
          WHERE event_name = 'purchase'
            AND event_date BETWEEN '20201201' AND '20201231'
        )
      GROUP BY user_pseudo_id
    )
  ) AS t1
CROSS JOIN
  (
    SELECT AVG(pageview_count) AS AVG_non_purchasers
    FROM (
      SELECT user_pseudo_id, COUNT(*) AS pageview_count
      FROM `bigquery-public-data`.`ga4_obfuscated_sample_ecommerce`.`events_*`
      WHERE event_name = 'page_view'
        AND event_date BETWEEN '20201201' AND '20201231'
        AND user_pseudo_id NOT IN (
          SELECT DISTINCT user_pseudo_id
          FROM `bigquery-public-data`.`ga4_obfuscated_sample_ecommerce`.`events_*`
          WHERE event_name = 'purchase'
            AND event_date BETWEEN '20201201' AND '20201231'
        )
      GROUP BY user_pseudo_id
    )
  ) AS t2;