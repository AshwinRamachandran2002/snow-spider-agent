/*  Re-run with consistent (un-quoted) column aliases to avoid case-sensitive
    identifier problems                                                                                                                                   */
WITH RECURSIVE
/* ------------------------------------------------------------------------- */
selected_publications AS (       -- 1
    SELECT
        p."publication_number"          AS publication_number,
        CAST(FLOOR(p."filing_date" / 10000) AS INTEGER)  AS filing_year,
        p."cpc"                         AS cpc_json
    FROM PATENTS.PATENTS.PUBLICATIONS p
    WHERE p."country_code" = 'DE'
      AND p."grant_date" BETWEEN 20161201 AND 20161231
      AND p."filing_date" IS NOT NULL
),
/* ------------------------------------------------------------------------- */
pub_with_cpc AS (                -- 2 & 3
    SELECT
        sp.publication_number,
        sp.filing_year,
        UPPER(SUBSTR(f.value:"code"::string, 1, 4))  AS cpc_group
    FROM selected_publications sp,
         LATERAL FLATTEN(input => sp.cpc_json) f
    WHERE f.value:"code" IS NOT NULL
),
/* ------------------------------------------------------------------------- */
yearly_counts AS (               -- 4
    SELECT
        cpc_group,
        filing_year,
        COUNT(DISTINCT publication_number) AS filings
    FROM pub_with_cpc
    GROUP BY cpc_group, filing_year
),
ordered_counts AS (
    SELECT
        cpc_group,
        filing_year,
        filings,
        ROW_NUMBER() OVER (PARTITION BY cpc_group ORDER BY filing_year) AS rn
    FROM yearly_counts
),
/* ------------------------------------------------------------------------- */
ema_recursive (cpc_group, filing_year, rn, ema) AS (    -- 5
    -- seed
    SELECT
        cpc_group,
        filing_year,
        rn,
        CAST(filings AS FLOAT) AS ema
    FROM ordered_counts
    WHERE rn = 1

    UNION ALL

    -- recursive step
    SELECT
        o.cpc_group,
        o.filing_year,
        o.rn,
        0.1 * o.filings + 0.9 * e.ema
    FROM ema_recursive e
    JOIN ordered_counts o
      ON e.cpc_group = o.cpc_group
     AND o.rn        = e.rn + 1
),
/* ------------------------------------------------------------------------- */
best_year_per_group AS (                         -- 6
    SELECT
        cpc_group,
        filing_year     AS peak_year,
        ema
    FROM (
        SELECT
            cpc_group,
            filing_year,
            ema,
            ROW_NUMBER() OVER (PARTITION BY cpc_group
                               ORDER BY ema DESC, filing_year ASC) AS rnk
        FROM ema_recursive
    )
    WHERE rnk = 1
)
/* ------------------------------------------------------------------------- */
SELECT                                         -- 7
    COALESCE(d."titleFull", 'Unknown')  AS full_title,
    b.cpc_group,
    b.peak_year       AS year_with_max_ema
FROM best_year_per_group b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
       ON d."symbol" = b.cpc_group
      AND d."level"  = 4
ORDER BY b.ema DESC NULLS LAST;