WITH all_events AS (
  SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201102`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201103`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201104`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201105`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201106`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201107`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201108`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201109`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201110`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201111`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201112`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201113`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201114`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201115`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201116`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201117`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201118`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201119`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201120`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201121`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201122`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201123`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201124`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201125`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201126`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201127`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201128`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201129`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201202`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201203`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201204`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201206`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201207`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201208`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201209`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201210`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201211`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201212`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201213`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201214`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201215`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201216`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201217`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201218`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201219`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201220`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201221`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201222`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201223`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201224`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201225`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201226`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201227`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201228`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201229`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201230`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201231`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210101`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210103`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210104`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210105`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210106`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210107`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210108`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210109`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210110`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210111`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210112`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210113`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210114`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210115`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210116`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210117`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210118`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210119`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210120`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210121`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210122`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210123`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210124`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210125`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210126`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210127`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210129`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210130`
  UNION ALL SELECT event_date, event_name, user_pseudo_id, items FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
),
tee_buyers AS (
  SELECT DISTINCT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', event_date)) AS month,
    user_pseudo_id
  FROM all_events
  WHERE event_name = 'purchase'
    AND EXISTS (
      SELECT 1 FROM UNNEST(items) AS i
      WHERE i.item_name = 'Google Red Speckled Tee'
    )
),
other_product_qty AS (
  SELECT
    tb.month,
    i.item_name,
    SUM(i.quantity) AS total_quantity
  FROM all_events e
  JOIN tee_buyers tb
    ON tb.user_pseudo_id = e.user_pseudo_id
   AND tb.month = FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', e.event_date))
  CROSS JOIN UNNEST(e.items) AS i
  WHERE e.event_name = 'purchase'
    AND i.item_name <> 'Google Red Speckled Tee'
  GROUP BY tb.month, i.item_name
),
ranked AS (
  SELECT
    month,
    item_name AS most_purchased_other_product,
    total_quantity,
    ROW_NUMBER() OVER (PARTITION BY month ORDER BY total_quantity DESC, item_name ASC) AS rk
  FROM other_product_qty
)
SELECT
  month,
  most_purchased_other_product,
  total_quantity
FROM ranked
WHERE rk = 1
ORDER BY month;