WITH months AS (
    /* All months from Jan‑2008 through Dec‑2022 (180 months) */
    SELECT
        DATE_TRUNC('month',
                   DATEADD(month, seq4(), TO_DATE('2008-01-01'))
        ) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 180))
),

pubs AS (   /* U.S. publications whose abstract contains the phrase 'internet of things' */
    SELECT
        DATE_TRUNC('month',
                   TO_DATE("filing_date"::TEXT,'YYYYMMDD')
        )                                            AS filing_month,
        COUNT(DISTINCT "publication_number")         AS pub_count
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "filing_date" BETWEEN 20080101 AND 20221231
      AND "abstract_localized" IS NOT NULL
      AND TO_VARCHAR("abstract_localized") ILIKE '%internet of things%'
    GROUP BY filing_month
)

SELECT
    m.month_start                  AS "FILING_MONTH",
    COALESCE(p.pub_count, 0)       AS "US_IOT_PUBLICATIONS"
FROM months m
LEFT JOIN pubs p
       ON m.month_start = p.filing_month
ORDER BY m.month_start;