-- Task: What are the top 3 months between 2010 and 2014 with the smallest absolute difference between the average air temperature and the average sea surface temperature, including respective years and differences? Please present the year and month in numerical format.

WITH monthly_averages AS (
    SELECT 
        year, 
        month,
        AVG(air_temperature) AS avg_air_temp,
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
      AND sea_surface_temp IS NOT NULL
    GROUP BY year, month
)
SELECT 
    year, 
    month,
    ROUND(ABS(avg_air_temp - avg_sst), 4) AS difference
FROM monthly_averages
ORDER BY difference ASC
LIMIT 3;