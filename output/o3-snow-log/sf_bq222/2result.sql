/* -------------------------------------------------------------
   CPC technology areas (level-4 groups) in Germany whose patents
   granted in December 2016 show the highest exponential moving
   average (α = 0.1) of yearly filings.
   ------------------------------------------------------------- */
WITH base_data AS (            /* 1. German patents granted in Dec-2016                       */
    SELECT
        p."publication_number",
        TO_NUMBER(LEFT(TO_VARCHAR(p."filing_date"),4))               AS filing_year,
        UPPER(SUBSTR(f.value:"code"::STRING,1,4))                    AS group_code          -- level-4 CPC
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN (INPUT => p."cpc") f
    WHERE p."country_code" = 'DE'
      AND p."grant_date" BETWEEN 20161201 AND 20161231               -- December 2016 grants
      AND f.value:"code" IS NOT NULL
),
yearly_filings AS (            /* 2. # filings by CPC-group & filing-year                     */
    SELECT
        group_code,
        filing_year,
        COUNT(DISTINCT "publication_number")        AS filings
    FROM base_data
    WHERE filing_year IS NOT NULL
    GROUP BY group_code, filing_year
),
ordered AS (                   /* 3. order rows for recursive EMA                            */
    SELECT  group_code,
            filing_year,
            filings,
            ROW_NUMBER() OVER (PARTITION BY group_code
                                ORDER BY filing_year) AS rn
    FROM yearly_filings
),
/* 4. Recursive EMA:  EMA_t = α·value_t + (1-α)·EMA_{t-1},  α = 0.1 */
ema_rec AS (
    SELECT group_code, filing_year, filings,
           filings::FLOAT                    AS ema,   /* first year: EMA = value */
           rn
    FROM   ordered
    WHERE  rn = 1
    UNION ALL
    SELECT o.group_code,
           o.filing_year,
           o.filings,
           0.1 * o.filings + 0.9 * e.ema     AS ema,
           o.rn
    FROM   ema_rec e
    JOIN   ordered  o
           ON  o.group_code = e.group_code
           AND o.rn       = e.rn + 1
),
/* 5. For every CPC group: keep the year where EMA is maximal        */
max_ema AS (
    SELECT  group_code,
            filing_year      AS year_with_max_ema,
            ema              AS max_ema,
            ROW_NUMBER() OVER (PARTITION BY group_code
                               ORDER BY ema DESC) AS rk
    FROM ema_rec
),
selected AS (
    SELECT group_code, year_with_max_ema, max_ema
    FROM   max_ema
    WHERE  rk = 1                                                -- highest EMA per group
),
/* 6. Attach CPC level-4 titles                                      */
with_titles AS (
    SELECT
        s.group_code,
        COALESCE(cd."titleFull",'(title not found)') AS full_title,
        s.year_with_max_ema,
        s.max_ema
    FROM selected s
    LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION cd
           ON cd."symbol" = s.group_code
          AND cd."level"  = 4
)
/* 7. Final output                                                   */
SELECT
    full_title,
    group_code        AS cpc_group,
    year_with_max_ema
FROM   with_titles
ORDER  BY max_ema DESC NULLS LAST;