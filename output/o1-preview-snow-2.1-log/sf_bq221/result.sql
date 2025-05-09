WITH filings_per_year AS (
    SELECT
        c."symbol" AS "symbol",
        c."titleFull" AS "titleFull",
        YEAR(TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD')) AS "filing_year",
        COUNT(*) AS "filing_count"
    FROM
        PATENTS.PATENTS.PUBLICATIONS t,
        LATERAL FLATTEN(input => t."cpc") f
    JOIN PATENTS.PATENTS.CPC_DEFINITION c
        ON c."level" = 5
        AND c."symbol" = LEFT(f.value:"code"::STRING, LENGTH(c."symbol"))
    WHERE
        TRY_TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD') IS NOT NULL
        AND f.value:"code"::STRING IS NOT NULL
    GROUP BY c."symbol", c."titleFull", "filing_year"
),
current_year_cte AS (
    SELECT MAX("filing_year") AS "current_year" FROM filings_per_year
),
ema_per_symbol AS (
    SELECT
        p."symbol",
        p."titleFull",
        ROUND(SUM(
            p."filing_count" * POWER(0.8::FLOAT, current_year_cte."current_year" - p."filing_year")
        ) * 0.2, 4) AS "EMA"
    FROM
        filings_per_year p
    CROSS JOIN
        current_year_cte
    GROUP BY p."symbol", p."titleFull"
),
best_year_per_symbol AS (
    SELECT
        p."symbol",
        p."filing_year" AS "Best_Year",
        ROW_NUMBER() OVER (
            PARTITION BY p."symbol"
            ORDER BY p."filing_count" DESC, p."filing_year" DESC
        ) AS rn
    FROM
        filings_per_year p
)
SELECT
    e."symbol" AS "CPC_Symbol",
    e."titleFull" AS "Full_Title",
    b."Best_Year"
FROM
    ema_per_symbol e
JOIN best_year_per_symbol b
    ON e."symbol" = b."symbol" AND b.rn = 1
ORDER BY e."EMA" DESC NULLS LAST
LIMIT 100;