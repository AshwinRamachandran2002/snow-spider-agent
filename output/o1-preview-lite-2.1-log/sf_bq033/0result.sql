WITH months AS (
    SELECT
        DATEADD(month, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2008-01-01') AS month_date
    FROM
        TABLE(GENERATOR(ROWCOUNT => ((2022 - 2008 + 1) * 12)))
),
publications_filtered AS (
    SELECT
        DATE_TRUNC('month', TO_DATE(TO_CHAR(t."filing_date"), 'YYYYMMDD')) AS filing_month
    FROM
        PATENTS.PATENTS.PUBLICATIONS t,
        LATERAL FLATTEN(input => t."abstract_localized") f
    WHERE
        t."country_code" = 'US'
        AND t."filing_date" BETWEEN 20080101 AND 20221231
        AND f.value['text']::STRING ILIKE '%internet of things%'
)
SELECT
    EXTRACT(year FROM m.month_date) AS "Year",
    EXTRACT(month FROM m.month_date) AS "Month",
    COALESCE(pc.num_publications, 0) AS "Num_Publications"
FROM
    months m
    LEFT JOIN (
        SELECT
            filing_month,
            COUNT(*) AS num_publications
        FROM
            publications_filtered
        GROUP BY
            filing_month
    ) pc ON pc.filing_month = m.month_date
ORDER BY
    "Year", "Month";