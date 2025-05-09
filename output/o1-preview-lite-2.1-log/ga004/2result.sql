SELECT
    ABS(AVG(IF(is_purchaser, pageviews, NULL)) - AVG(IF(NOT is_purchaser, pageviews, NULL))) AS Average_Difference_in_Pageviews
FROM
(
    SELECT
        user_pseudo_id,
        COUNTIF(event_name = 'page_view') AS pageviews,
        COUNTIF(event_name = 'purchase') > 0 AS is_purchaser
    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE
        _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    GROUP BY
        user_pseudo_id
)