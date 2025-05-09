WITH months AS (   -- every calendar month from 2008-01 through 2022-12
    SELECT
        TO_CHAR(
            DATE_TRUNC('month',
                       DATEADD(month, seq4(), TO_DATE('2008-01-01'))
            ),
            'YYYY-MM'
        ) AS month
    FROM TABLE(GENERATOR(ROWCOUNT => 180))            -- 15 years * 12 months
),
iot AS (          -- U.S. publications whose abstract mentions “internet of things”
    SELECT DISTINCT
        "publication_number",
        TO_CHAR(
            DATE_TRUNC('month',
                       TO_DATE("filing_date"::string, 'YYYYMMDD')
            ),
            'YYYY-MM'
        ) AS month
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "filing_date" BETWEEN 20080101 AND 20221231
      AND "filing_date" IS NOT NULL
      AND LOWER(TO_VARCHAR("abstract_localized")) LIKE '%internet of things%'
),
counts AS (       -- monthly counts of such publications
    SELECT
        month,
        COUNT(*) AS filings_count
    FROM iot
    GROUP BY month
)
SELECT
    m.month,
    COALESCE(c.filings_count, 0) AS filings_count
FROM months m
LEFT JOIN counts c USING (month)
ORDER BY m.month;