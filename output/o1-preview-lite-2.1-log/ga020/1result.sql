WITH retention_rates AS (
  SELECT
    initial.event_name AS quickplay_event_type,
    (retained.retained_users / initial.total_users) * 100 AS retention_rate_second_week
  FROM (
    SELECT
      event_name,
      COUNT(DISTINCT user_pseudo_id) AS total_users
    FROM
      `firebase-public-project.analytics_153293282.events_*`
    WHERE
      LOWER(event_name) LIKE '%quickplay%'
      AND TIMESTAMP_MICROS(event_timestamp) BETWEEN TIMESTAMP('2018-08-01') AND TIMESTAMP('2018-08-15')
    GROUP BY
      event_name
  ) AS initial
  LEFT JOIN (
    SELECT
      e.event_name,
      COUNT(DISTINCT e.user_pseudo_id) AS retained_users
    FROM
      `firebase-public-project.analytics_153293282.events_*` e
    JOIN (
      SELECT
        user_pseudo_id,
        MIN(event_timestamp) AS first_engagement_timestamp
      FROM
        `firebase-public-project.analytics_153293282.events_*`
      GROUP BY
        user_pseudo_id
      HAVING
        TIMESTAMP_MICROS(MIN(event_timestamp)) BETWEEN TIMESTAMP('2018-08-01') AND TIMESTAMP('2018-08-15')
    ) AS initial_users
    ON
      e.user_pseudo_id = initial_users.user_pseudo_id
    WHERE
      LOWER(e.event_name) LIKE '%quickplay%'
      AND TIMESTAMP_MICROS(e.event_timestamp) BETWEEN
        TIMESTAMP_MICROS(initial_users.first_engagement_timestamp + 7 * 86400000000) AND
        TIMESTAMP_MICROS(initial_users.first_engagement_timestamp + 14 * 86400000000)
    GROUP BY
      e.event_name
  ) AS retained
  ON
    initial.event_name = retained.event_name
)
SELECT
  quickplay_event_type,
  ROUND(retention_rate_second_week, 4) AS retention_rate_second_week
FROM
  retention_rates
ORDER BY
  retention_rate_second_week ASC
LIMIT
  1;