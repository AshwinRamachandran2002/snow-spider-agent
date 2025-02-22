-- Task: Provide the highest recorded precipitation, minimum temperature, and maximum temperature from the last 15 days of 2013 at weather station USW00094846, using only validated data (non-null values and no quality flags). Ensure each value represents the peak measurement for that period, with precipitation in millimeters and temperatures in degrees Celsius.

SELECT
  EXTRACT(YEAR FROM wx.date) AS year,
  MAX(IF(wx.element = 'PRCP', wx.value/10, NULL)) AS max_prcp,
  MAX(IF(wx.element = 'TMIN', wx.value/10, NULL)) AS max_tmin,
  MAX(IF(wx.element = 'TMAX', wx.value/10, NULL)) AS max_tmax
FROM
  `bigquery-public-data.ghcn_d.ghcnd_2013` AS wx
WHERE
  wx.id = 'USW00094846' AND
  wx.qflag IS NULL AND
  wx.value IS NOT NULL AND
  DATE_DIFF(DATE('2013-12-31'), wx.date, DAY) < 15
GROUP BY
  year;