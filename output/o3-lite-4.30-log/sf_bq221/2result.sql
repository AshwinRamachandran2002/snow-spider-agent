WITH RECURSIVE
/* 1. first CPC code for each publication that has a valid filing date & application number */
first_cpc AS (
    SELECT
        p."publication_number",
        FLOOR(p."filing_date" / 10000)                                    AS filing_year,
        TRIM(COALESCE(f.value:"code"::STRING, f.value:"symbol"::STRING))  AS cpc_code
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc") f
    WHERE p."application_number" IS NOT NULL
      AND p."application_number" <> ''
      AND p."filing_date" IS NOT NULL
      AND p."filing_date" > 0
    QUALIFY ROW_NUMBER() OVER (PARTITION BY p."publication_number" ORDER BY f.index) = 1
),
/* 2. keep only codes that map to a level‑5 CPC symbol */
level5_codes AS (
    SELECT
        d."symbol"        AS cpc_symbol,          -- level‑5 symbol
        fc.filing_year
    FROM first_cpc fc
    JOIN PATENTS.PATENTS.CPC_DEFINITION d
          ON fc.cpc_code LIKE d."symbol" || '%'
    WHERE d."level" = 5
),
/* 3. yearly counts of filings per level‑5 CPC symbol */
yearly_counts AS (
    SELECT
        cpc_symbol,
        filing_year,
        COUNT(*)                        AS n_filings
    FROM level5_codes
    GROUP BY cpc_symbol, filing_year
),
/* 4. order years inside each CPC for recursive EMA */
ordered_counts AS (
    SELECT
        yc.*,
        ROW_NUMBER() OVER (PARTITION BY cpc_symbol ORDER BY filing_year) AS rn
    FROM yearly_counts yc
),
/* 5. recursive EMA calculation with α = 0.2 */
ema_cte AS (
    -- anchor
    SELECT
        cpc_symbol,
        filing_year,
        n_filings,
        0.2 * n_filings                       AS ema,
        rn
    FROM ordered_counts
    WHERE rn = 1

    UNION ALL

    -- recursive step
    SELECT
        o.cpc_symbol,
        o.filing_year,
        o.n_filings,
        0.2 * o.n_filings + 0.8 * e.ema      AS ema,
        o.rn
    FROM ema_cte e
    JOIN ordered_counts o
      ON o.cpc_symbol = e.cpc_symbol
     AND o.rn        = e.rn + 1
),
/* 6. pick the year with the highest EMA for each CPC symbol */
best_years AS (
    SELECT
        cpc_symbol,
        filing_year                 AS best_year,
        ema                         AS highest_exponential_moving_average,
        ROW_NUMBER() OVER (PARTITION BY cpc_symbol
                           ORDER BY ema DESC, filing_year) AS rn
    FROM ema_cte
)
/* 7. final output with CPC full title */
SELECT
    d."titleFull"                                  AS cpc_full_title,
    b.best_year,
    ROUND(b.highest_exponential_moving_average, 4) AS highest_exponential_moving_average
FROM best_years b
JOIN PATENTS.PATENTS.CPC_DEFINITION d
  ON b.cpc_symbol = d."symbol"
WHERE b.rn = 1
ORDER BY highest_exponential_moving_average DESC NULLS LAST;