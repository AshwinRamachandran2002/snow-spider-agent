WITH RECURSIVE

/* 1. Select the first CPC code for each publication */
first_cpc AS (
    SELECT
        p."publication_number",
        MIN_BY(f.value:"code"::STRING, f.index) AS "cpc_code"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc") f
    GROUP BY p."publication_number"
),

/* 2. Keep publications with valid data and map detailed CPC to its level-5 group */
valid_pubs AS (
    SELECT
        SUBSTR(fc."cpc_code", 1, 4)                    AS "cpc_lvl5",
        CAST(FLOOR(p."filing_date" / 10000) AS NUMBER) AS "year"
    FROM first_cpc fc
    JOIN PATENTS.PATENTS.PUBLICATIONS p
          ON p."publication_number" = fc."publication_number"
    WHERE p."application_number" IS NOT NULL
      AND p."filing_date"        IS NOT NULL
      AND FLOOR(p."filing_date" / 10000) > 0
),

/* 3. Yearly filing counts per level-5 CPC */
yearly AS (
    SELECT
        "cpc_lvl5",
        "year",
        COUNT(*) AS "filings"
    FROM valid_pubs
    GROUP BY "cpc_lvl5", "year"
),

/* 4. Row numbers to impose chronological order */
ordered AS (
    SELECT
        y.*,
        ROW_NUMBER() OVER (PARTITION BY y."cpc_lvl5" ORDER BY y."year") AS rn
    FROM yearly y
),

/* 5. Recursive EMA calculation (α = 0.2) */
ema_cte AS (
    SELECT
        o."cpc_lvl5",
        o."year",
        o."filings",
        o.rn,
        o."filings"::FLOAT AS ema
    FROM ordered o
    WHERE o.rn = 1

    UNION ALL

    SELECT
        o."cpc_lvl5",
        o."year",
        o."filings",
        o.rn,
        0.2 * o."filings" + 0.8 * e.ema AS ema
    FROM ema_cte e
    JOIN ordered o
      ON o."cpc_lvl5" = e."cpc_lvl5"
     AND o.rn        = e.rn + 1
),

/* 6. Best (peak-EMA) year per CPC group */
best_years AS (
    SELECT
        "cpc_lvl5",
        MAX_BY("year", ema) AS "best_year",
        MAX(ema)            AS "max_ema"
    FROM ema_cte
    GROUP BY "cpc_lvl5"
)

/* 7. Attach CPC title and present the result */
SELECT
    b."cpc_lvl5"  AS "cpc_group",
    d."titleFull" AS "cpc_title",
    b."best_year",
    b."max_ema"
FROM best_years b
JOIN PATENTS.PATENTS.CPC_DEFINITION d
  ON d."symbol" = b."cpc_lvl5"
WHERE d."level" = 5
ORDER BY b."max_ema" DESC NULLS LAST,
         b."cpc_lvl5";