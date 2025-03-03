WITH valid_temps AS (
    SELECT
        DATE(CONCAT(year, '-', LPAD(mo,2,'0'), '-', LPAD(da,2,'0'))) AS date,
        AVG(temp) AS avg_temp
    FROM
        `bigquery-public-data.noaa_gsod.gsod*`
    WHERE
        _TABLE_SUFFIX BETWEEN '2008' AND '2017'
        AND stn IN ('725030', '744860')
        AND temp != 9999.9
    GROUP BY
        date
),
daily_complaints AS (
    SELECT
        DATE(created_date) AS date,
        complaint_type,
        COUNT(*) AS daily_complaint_count
    FROM
        `bigquery-public-data.new_york.311_service_requests`
    WHERE
        EXTRACT(YEAR FROM created_date) BETWEEN 2008 AND 2017
    GROUP BY
        date, complaint_type
),
total_daily_complaints AS (
    SELECT
        date,
        SUM(daily_complaint_count) AS total_daily_complaints
    FROM
        daily_complaints
    GROUP BY
        date
),
complaints_with_temps AS (
    SELECT
        c.date,
        c.complaint_type,
        c.daily_complaint_count,
        t.avg_temp,
        total.total_daily_complaints
    FROM
        daily_complaints c
    JOIN
        valid_temps t ON c.date = t.date
    JOIN
        total_daily_complaints total ON c.date = total.date
),
complaints_with_stats AS (
    SELECT
        complaint_type AS Complaint_Type,
        SUM(daily_complaint_count) AS Total_Complaints,
        COUNT(DISTINCT date) AS Total_Days_with_Valid_Temperature_Records,
        ROUND(CORR(daily_complaint_count, avg_temp), 4) AS Pearson_Correlation_Count_Temperature,
        ROUND(CORR(SAFE_DIVIDE(daily_complaint_count, total_daily_complaints), avg_temp), 4) AS Pearson_Correlation_Percentage_Temperature
    FROM
        complaints_with_temps
    GROUP BY
        complaint_type
    HAVING
        Total_Complaints > 5000
        AND ABS(Pearson_Correlation_Count_Temperature) > 0.5
)
SELECT
    Complaint_Type,
    Total_Complaints,
    Total_Days_with_Valid_Temperature_Records,
    Pearson_Correlation_Count_Temperature,
    Pearson_Correlation_Percentage_Temperature
FROM
    complaints_with_stats
ORDER BY
    Total_Complaints DESC;