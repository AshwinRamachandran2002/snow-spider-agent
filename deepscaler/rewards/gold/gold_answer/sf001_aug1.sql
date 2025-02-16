-- Task: Given today's date is April 1, 2024, find the dates of the week ending after the first two full weeks of the previous year.
WITH timestamps AS
(
    SELECT
        DATE_TRUNC(year, DATEADD(year, -1, DATE '2024-04-01')) AS "ref_timestamp",
        LAST_DAY(
            DATEADD(
                week,
                2 + CAST(WEEKISO(DATE_TRUNC(year, DATEADD(year, -1, DATE '2024-04-01'))) != 1 AS INTEGER),
                DATE_TRUNC(year, DATEADD(year, -1, DATE '2024-04-01'))
            ),
            week
        ) AS "end_week",
        DATEADD(day, "day_num" - 7, "end_week") AS "date_valid_std"
    FROM
    (
        SELECT
            ROW_NUMBER() OVER (ORDER BY SEQ1()) AS "day_num"
        FROM
            TABLE(GENERATOR(rowcount => 7))
    ) 
)
SELECT "date_valid_std"
FROM timestamps
ORDER BY "date_valid_std";