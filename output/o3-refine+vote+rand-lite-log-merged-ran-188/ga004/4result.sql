WITH user_pageviews AS (
  SELECT
    user_pseudo_id,
    COUNTIF(event_name = 'page_view')                                    AS pageviews,
    LOGICAL_OR(event_name = 'purchase')                                  AS is_purchaser
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'                      -- December 2020 only
  GROUP BY
    user_pseudo_id
)

SELECT
  ROUND(AVG(CASE WHEN is_purchaser     THEN pageviews END), 4) AS avg_pageviews_purchasers,
  ROUND(AVG(CASE WHEN NOT is_purchaser THEN pageviews END), 4) AS avg_pageviews_non_purchasers,
  ROUND(
        AVG(CASE WHEN is_purchaser     THEN pageviews END) -
        AVG(CASE WHEN NOT is_purchaser THEN pageviews END)
  , 4)                                                                AS avg_difference
FROM user_pageviews;