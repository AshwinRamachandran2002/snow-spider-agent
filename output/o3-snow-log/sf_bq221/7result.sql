/*  Exponential-moving average (α = 0.20) of yearly patent-filings for the
    primary (first-flagged) CPC level-5 group (first 4 characters).          */
WITH
/* 1) retain only the FIRST CPC element, valid filing-date, and application # */
primary_cpc AS (
    SELECT  p."publication_number",
            FLOOR(p."filing_date" / 10000)               AS filing_year,
            LEFT(c.value:"code"::STRING, 4)              AS cpc_group_lvl5
    FROM   PATENTS.PATENTS.PUBLICATIONS  p,
           LATERAL FLATTEN ( INPUT => p."cpc")           c
    WHERE  COALESCE(c.value:"first"::BOOLEAN, FALSE) = TRUE
      AND  p."filing_date"        IS NOT NULL
      AND  p."application_number" IS NOT NULL
),
/* 2) yearly counts of filings per CPC group */
yearly_cnt AS (
    SELECT  cpc_group_lvl5   AS group_code,
            filing_year,
            COUNT(DISTINCT "publication_number") AS num_filings
    FROM    primary_cpc
    GROUP BY group_code, filing_year
),
/* 3) chronological ordering inside each CPC group */
ordered AS (
    SELECT  group_code,
            filing_year,
            num_filings,
            ROW_NUMBER() OVER (PARTITION BY group_code ORDER BY filing_year) AS rn
    FROM    yearly_cnt
),
/* 4) recursive EMA calculation: EMA_t = 0.2*value_t + 0.8*EMA_(t-1) */
ema_calc AS (
      /* anchor (first year for each group) */
      SELECT  group_code,
              filing_year,
              num_filings,
              CAST(num_filings AS FLOAT) AS ema,
              rn
      FROM    ordered
      WHERE   rn = 1
      UNION ALL
      /* recursive step */
      SELECT  o.group_code,
              o.filing_year,
              o.num_filings,
              0.2 * o.num_filings + 0.8 * e.ema          AS ema,
              o.rn
      FROM    ordered  o
      JOIN    ema_calc e
        ON    o.group_code = e.group_code
       AND    o.rn        = e.rn + 1
),
/* 5) pick the year in which each CPC group reaches its highest EMA */
best_per_group AS (
    SELECT  group_code,
            filing_year        AS best_year,
            ema                AS best_ema,
            ROW_NUMBER() OVER (PARTITION BY group_code
                               ORDER BY ema DESC, filing_year) AS rnk
    FROM    ema_calc
)
/* 6) enrich with CPC title and list results */
SELECT  b.group_code                AS "cpc_group_lvl5",
        d."titleFull"               AS "cpc_title_full",
        b.best_year,
        b.best_ema
FROM    best_per_group           b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
       ON d."symbol" = b.group_code
WHERE   b.rnk = 1            -- one record (peak year) per CPC group
  AND   d."titleFull" IS NOT NULL
ORDER  BY b.best_ema DESC NULLS LAST;