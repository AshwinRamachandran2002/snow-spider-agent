WITH RECURSIVE
/* 1) First CPC code for each publication having a valid filing date
       and a non-empty application number                                        */
first_cpc AS (
    SELECT
        p."publication_number",
        LEFT(p."filing_date", 4)::INT                 AS filing_year,
        f.value:"code"::STRING                       AS cpc_code
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc") f
    WHERE p."filing_date" IS NOT NULL
      AND p."filing_date" <> 0
      AND p."application_number" IS NOT NULL
      AND p."application_number" <> ''
    QUALIFY ROW_NUMBER() OVER (PARTITION BY p."publication_number"
                               ORDER BY f.index) = 1
),

/* 2) Map every detailed CPC to its level-5 (4-character) technology area         */
level5 AS (
    SELECT
        LEFT(cpc_code, 4) AS level5_code,
        filing_year
    FROM first_cpc
    WHERE filing_year IS NOT NULL
),

/* 3) Yearly filing counts per level-5 group                                      */
yearly_counts AS (
    SELECT
        level5_code,
        filing_year,
        COUNT(*) AS filings
    FROM level5
    GROUP BY level5_code, filing_year
),

/* 4) Row number to keep years in chronological order inside each group           */
yearly_counts_rn AS (
    SELECT
        level5_code,
        filing_year,
        filings,
        ROW_NUMBER() OVER (PARTITION BY level5_code
                           ORDER BY filing_year) AS rn
    FROM yearly_counts
),

/* 5) Recursive computation of EMA with α = 0.2                                   */
ema_calc AS (
    /* anchor : first year for every group                                         */
    SELECT
        level5_code,
        filing_year,
        filings,
        CAST(filings AS FLOAT) AS ema,
        rn
    FROM yearly_counts_rn
    WHERE rn = 1

    UNION ALL

    /* recursive: EMAt = 0.2*valuet + 0.8*EMAt-1                                   */
    SELECT
        y.level5_code,
        y.filing_year,
        y.filings,
        0.2 * y.filings + 0.8 * e.ema  AS ema,
        y.rn
    FROM yearly_counts_rn y
    JOIN ema_calc        e
      ON y.level5_code = e.level5_code
     AND y.rn           = e.rn + 1
),

/* 6) Year where the EMA peaks for each CPC group                                 */
best_per_group AS (
    SELECT
        level5_code,
        filing_year  AS best_year,
        ema          AS max_ema,
        ROW_NUMBER() OVER (PARTITION BY level5_code
                           ORDER BY ema DESC) AS rk
    FROM ema_calc
)

/* 7) Attach full CPC title (level-5 rows) and display                            */
SELECT
    b.level5_code                       AS "cpc_group",
    d."titleFull"                       AS "cpc_title",
    b.best_year                         AS "best_year",
    ROUND(b.max_ema, 4)                 AS "highest_ema"
FROM best_per_group b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
       ON d."symbol" = b.level5_code
WHERE b.rk = 1
  AND d."level" = 5
ORDER BY b.max_ema DESC NULLS LAST;