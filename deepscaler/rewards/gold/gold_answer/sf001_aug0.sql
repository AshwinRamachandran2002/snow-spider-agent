-- Task: Assuming today is April 1, 2024, I would like to know the daily snowfall amounts greater than 6 inches for each U.S. postal code during the week following the first two full weeks of the previous year (i.e., the third full week of January 2023). Show the postal code, date, and snowfall amount.

WITH ref_timestamp AS
(
    SELECT DATE_TRUNC('year', DATEADD(year, -1, DATE '2024-04-01')) AS ref_date
),
target_week AS
(
    SELECT
        DATEADD(week, 2, ref_date) AS start_date,
        DATEADD(day, 6, DATEADD(week, 2, ref_date)) AS end_date
    FROM ref_timestamp
),
dates AS
(
    SELECT
        DATEADD(day, day_offset, start_date) AS date_valid_std
    FROM
        target_week,
        LATERAL
        (
            SELECT SEQ4() AS day_offset
            FROM TABLE(GENERATOR(ROWCOUNT => 7))
        )
)
SELECT
    postal_code,
    date_valid_std AS date,
    tot_snowfall_in AS snowfall_amount
FROM
    GLOBAL_WEATHER__CLIMATE_DATA_FOR_BI.STANDARD_TILE.HISTORY_DAY
JOIN
    dates USING(date_valid_std)
WHERE
    country = 'US' AND
    tot_snowfall_in > 6.0
ORDER BY
    postal_code, date_valid_std;