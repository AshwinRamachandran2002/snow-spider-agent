-- Task: Identify the top 3 months between 2010 and 2014 with the smallest total sum of absolute differences among the monthly average values of air_temperature, wetbulb_temperature, dewpoint_temperature, and sea_surface_temp. For each month, calculate the average of each temperature, then compute the sum of absolute differences among all pairs of these averages. Include the respective year, month (in numerical format), and the sum of differences (rounded to 4 decimal places) in the results.

WITH monthly_averages AS (
    SELECT 
        year, 
        month,
        AVG(air_temperature) AS avg_air_temp,
        AVG(wetbulb_temperature) AS avg_wetbulb_temp,
        AVG(dewpoint_temperature) AS avg_dewpoint_temp,
        AVG(sea_surface_temp) AS avg_sst
    FROM (
        SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2010`
        UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2011`
        UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2012`
        UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2013`
        UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_icoads.icoads_core_2014`
    ) AS combined_data
    WHERE year BETWEEN 2010 AND 2014
      AND air_temperature IS NOT NULL
      AND wetbulb_temperature IS NOT NULL
      AND dewpoint_temperature IS NOT NULL
      AND sea_surface_temp IS NOT NULL
    GROUP BY year, month
)
SELECT 
    year, 
    month,
    ROUND(
        ABS(avg_air_temp - avg_wetbulb_temp)
        + ABS(avg_air_temp - avg_dewpoint_temp)
        + ABS(avg_air_temp - avg_sst)
        + ABS(avg_wetbulb_temp - avg_dewpoint_temp)
        + ABS(avg_wetbulb_temp - avg_sst)
        + ABS(avg_dewpoint_temp - avg_sst)
    ,4) AS sum_of_differences
FROM monthly_averages
ORDER BY sum_of_differences ASC
LIMIT 3;