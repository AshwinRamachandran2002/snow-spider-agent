SELECT
  UPPER(state) AS State,
  COUNT(*) AS Number_of_Storm_Events
FROM (
  SELECT state
  FROM (
    SELECT
      state,
      ROW_NUMBER() OVER (
        PARTITION BY EXTRACT(YEAR FROM event_begin_time)
        ORDER BY magnitude DESC
      ) AS rn
    FROM (
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1980`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1981`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1982`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1983`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1984`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1985`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1986`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1987`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1988`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1989`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1990`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1991`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1992`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1993`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1994`
      UNION ALL
      SELECT state, magnitude, event_begin_time
      FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1995`
    )
    WHERE magnitude IS NOT NULL
  )
  WHERE rn <= 1000
)
GROUP BY State
ORDER BY Number_of_Storm_Events DESC
LIMIT 5;