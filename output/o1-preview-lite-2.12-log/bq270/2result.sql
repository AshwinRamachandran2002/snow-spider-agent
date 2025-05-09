SELECT
  FORMAT_DATE('%b-%Y', PARSE_DATE('%Y%m%d', t.date)) AS Month,
  ROUND(
    SAFE_MULTIPLY(
      SAFE_DIVIDE(
        SUM(CASE WHEN h.eCommerceAction.action_type = '3' THEN 1 ELSE 0 END),
        SUM(CASE WHEN h.page.pagePath LIKE '%.axd%' THEN 1 ELSE 0 END)
      ),
      100
    ),
    4
  ) AS Add_to_Cart_Conversion_Rate,
  ROUND(
    SAFE_MULTIPLY(
      SAFE_DIVIDE(
        SUM(CASE WHEN h.eCommerceAction.action_type = '6' THEN 1 ELSE 0 END),
        SUM(CASE WHEN h.page.pagePath LIKE '%.axd%' THEN 1 ELSE 0 END)
      ),
      100
    ),
    4
  ) AS Purchase_Conversion_Rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
UNNEST(t.hits) AS h
WHERE t.date BETWEEN '20170101' AND '20170331'
GROUP BY Month
ORDER BY PARSE_DATE('%b-%Y', Month);