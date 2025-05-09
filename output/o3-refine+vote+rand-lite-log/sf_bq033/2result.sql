WITH iot_pubs AS (
    /* Count U.S. publications whose abstract contains the exact phrase
       'internet of things' (case–insensitive) and whose filing date is
       between 2008‑01‑01 and 2022‑12‑31.                          */
    SELECT
        DATE_TRUNC('month',
                   TO_DATE(TO_CHAR("filing_date"), 'YYYYMMDD')) AS month_start,
        COUNT(*)                                             AS filings
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "filing_date" BETWEEN 20080101 AND 20221231
      AND LOWER("abstract_localized"::string) LIKE '%internet of things%'
    GROUP BY month_start
),

months AS (
    /* Produce one row for every month from 2008‑01 through 2022‑12. */
    SELECT DATE_TRUNC('month',
                      DATEADD(month, seq4(), '2008-01-01')) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 180))         -- 15 years × 12 months
)

SELECT
    TO_CHAR(m.month_start, 'YYYY-MM') AS "month",
    COALESCE(p.filings, 0)            AS "us_publications"
FROM months m
LEFT JOIN iot_pubs p
       ON m.month_start = p.month_start
ORDER BY m.month_start;