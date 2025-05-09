/* 1)  Patents granted in Germany (country_code = 'DE') during December 2016
   2)  Flatten their CPC codes and reduce each code to its level‑4 group (first 4 characters)
   3)  Count filings per CPC group and filing year
   4)  Compute the Exponential Moving Average (α = 0.1) per group with a recursive CTE
   5)  Pick, for every group, the year with the highest EMA
   6)  Add the full CPC title (level = 4) from CPC_DEFINITION
*/
WITH dec16_de_pubs AS (          -- step 1
    SELECT
        "publication_number",
        "filing_date",
        "cpc"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'DE'
      AND "grant_date" BETWEEN 20161201 AND 20161231
      AND "cpc" IS NOT NULL
),
cpc_flat AS (                    -- step 2
    SELECT
        p."publication_number",
        p."filing_date",
        UPPER(SUBSTR(c.value:"code"::STRING , 1 , 4)) AS cpc_group
    FROM dec16_de_pubs p,
         LATERAL FLATTEN(input => p."cpc") c
    WHERE c.value:"code" IS NOT NULL
),
yearly_counts AS (               -- step 3
    SELECT
        cpc_group,
        TO_NUMBER(SUBSTR(TO_VARCHAR("filing_date"),1,4)) AS filing_year,
        COUNT(DISTINCT "publication_number")             AS filings
    FROM cpc_flat
    GROUP BY cpc_group , filing_year
),
ordered_counts AS (
    SELECT
        cpc_group,
        filing_year,
        filings,
        ROW_NUMBER() OVER (PARTITION BY cpc_group ORDER BY filing_year) AS rn
    FROM yearly_counts
),
recursive_ema AS (               -- step 4
    /* anchor rows (first year per group) */
    SELECT
        cpc_group,
        filing_year,
        filings,
        rn,
        filings * 0.1 AS ema
    FROM ordered_counts
    WHERE rn = 1
    UNION ALL
    /* subsequent years */
    SELECT
        o.cpc_group,
        o.filing_year,
        o.filings,
        o.rn,
        (0.1 * o.filings) + (0.9 * r.ema) AS ema
    FROM ordered_counts o
    JOIN recursive_ema  r
      ON  o.cpc_group = r.cpc_group
     AND o.rn        = r.rn + 1
),
best_year AS (                   -- step 5
    SELECT
        cpc_group,
        filing_year AS best_year
    FROM (
        SELECT
            cpc_group,
            filing_year,
            ema,
            ROW_NUMBER() OVER (PARTITION BY cpc_group ORDER BY ema DESC, filing_year DESC) AS rnk
        FROM recursive_ema
    )
    WHERE rnk = 1
)
SELECT                             -- step 6
    d."titleFull"                  AS full_title,
    b.cpc_group,
    b.best_year
FROM best_year                b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
       ON  d."symbol" = b.cpc_group
      AND d."level"  = 4
ORDER BY b.cpc_group;