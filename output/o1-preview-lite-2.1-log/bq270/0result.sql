SELECT
  Month,
  ROUND((Add_To_Cart_Actions / Product_Detail_Views) * 100, 4) AS Add_to_Cart_Conversion_Rate,
  ROUND((Purchase_Actions / Product_Detail_Views) * 100, 4) AS Purchase_Conversion_Rate
FROM
(
  SELECT
    Month,
    COUNT(DISTINCT IF(action_type = '3', HitID, NULL)) AS Add_To_Cart_Actions,
    COUNT(DISTINCT IF(action_type = '6', HitID, NULL)) AS Purchase_Actions,
    COUNT(DISTINCT IF(action_type = '2', HitID, NULL)) AS Product_Detail_Views
  FROM
  (
    SELECT
      FORMAT_DATE('%b-%Y', PARSE_DATE('%Y%m%d', date)) AS Month,
      CONCAT(fullVisitorId, '_', CAST(visitId AS STRING), '_', CAST(hit.hitNumber AS STRING)) AS HitID,
      hit.eCommerceAction.action_type AS action_type
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hit
    WHERE
      _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
      AND EXISTS (
        SELECT 1 FROM UNNEST(hit.product) AS product
        WHERE product.isImpression IS NULL OR product.isImpression = FALSE
      )
      AND hit.eCommerceAction.action_type IN ('2', '3', '6')
  )
  GROUP BY Month
)
ORDER BY PARSE_DATE('%b-%Y', Month);