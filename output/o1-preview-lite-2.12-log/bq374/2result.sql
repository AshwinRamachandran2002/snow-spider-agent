SELECT
  ROUND(
    (
      SELECT
        COUNT(DISTINCT initial_visits.fullVisitorId)
      FROM
        (
          SELECT
            fullVisitorId
          FROM
            `bigquery-public-data.google_analytics_sample.ga_sessions_*`
          WHERE
            _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
            AND visitNumber = 1
            AND totals.newVisits = 1
            AND IFNULL(totals.timeOnSite, 0) > 300
        ) AS initial_visits
      INNER JOIN
        (
          SELECT
            DISTINCT fullVisitorId
          FROM
            `bigquery-public-data.google_analytics_sample.ga_sessions_*`
          WHERE
            visitNumber > 1
            AND totals.transactions > 0
        ) AS subsequent_purchases
      ON
        initial_visits.fullVisitorId = subsequent_purchases.fullVisitorId
    ) /
    (
      SELECT
        COUNT(DISTINCT fullVisitorId)
      FROM
        `bigquery-public-data.google_analytics_sample.ga_sessions_*`
      WHERE
        _TABLE_SUFFIX BETWEEN '20160801' AND '20170430'
        AND visitNumber = 1
        AND totals.newVisits = 1
    )
    * 100,
    4
  ) AS Percentage_of_new_users_who_stayed_over_5_minutes_and_made_purchase