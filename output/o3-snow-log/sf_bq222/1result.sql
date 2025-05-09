/*---------------------------------------------------------------
  CPC level-4 groups that appear in German patents granted in
  December-2016 and whose yearly patent-filing series (within this
  sample) reach the highest exponential moving average
  (α = 0.1).  For every CPC group the query returns its symbol,
  the full CPC title, and the year in which its EMA is maximal.
----------------------------------------------------------------*/
WITH RECURSIVE
/* 1. German publications granted in December-2016 ----------------*/
de_dec2016_pubs AS (
    SELECT  p."publication_number",
            p."filing_date",
            p."cpc"
    FROM    PATENTS.PATENTS.PUBLICATIONS p
    WHERE   p."country_code" = 'DE'
      AND   p."grant_date"   BETWEEN 20161201 AND 20161231
),
/* 2. Explode CPC array to individual codes ----------------------*/
cpc_codes AS (
    SELECT  d."publication_number",
            f.value:"code"::string AS full_cpc_code
    FROM    de_dec2016_pubs d,
            LATERAL FLATTEN(input => d."cpc") f
),
/* 3. Derive level-4 CPC symbol (first 4 characters) -------------*/
cpc_level4 AS (
    SELECT  DISTINCT
            c."publication_number",
            SUBSTR(REGEXP_REPLACE(c.full_cpc_code,'\s',''),1,4) AS cpc_group
    FROM    cpc_codes c
),
/* 4. Yearly filing counts for every CPC group -------------------*/
filings_per_year AS (
    SELECT  g.cpc_group,
            TO_NUMBER(TO_CHAR(TO_DATE(p."filing_date"::string,'YYYYMMDD'),'YYYY')) AS filing_year,
            COUNT(*) AS filings
    FROM    cpc_level4 g
    JOIN    de_dec2016_pubs p
           ON p."publication_number" = g."publication_number"
    WHERE   p."filing_date" IS NOT NULL
    GROUP BY g.cpc_group, filing_year
),
/* 5. Order years inside each CPC group --------------------------*/
ordered AS (
    SELECT  c.*,
            ROW_NUMBER() OVER (PARTITION BY c.cpc_group ORDER BY c.filing_year) AS rn
    FROM    filings_per_year c
),
/* 6. Recursive EMA computation  ---------------------------------*/
ema_rec (cpc_group, rn, filing_year, filings, ema) AS (
      /* seed row (first year) */
      SELECT  o.cpc_group,
              o.rn,
              o.filing_year,
              o.filings,
              o.filings::FLOAT                       AS ema          -- EMA_1 = value_1
      FROM    ordered o
      WHERE   o.rn = 1
      UNION ALL
      /* recursive step: EMA_n = 0.1*value_n + 0.9*EMA_{n-1} */
      SELECT  o.cpc_group,
              o.rn,
              o.filing_year,
              o.filings,
              (0.1 * o.filings) + (0.9 * r.ema)      AS ema
      FROM    ema_rec r
      JOIN    ordered o
             ON  o.cpc_group = r.cpc_group
             AND o.rn        = r.rn + 1
),
/* 7. Pick the year of maximum EMA for each CPC group ------------*/
max_ema_year AS (
    SELECT  cpc_group,
            filing_year,
            ema,
            ROW_NUMBER() OVER (PARTITION BY cpc_group
                               ORDER BY ema DESC, filing_year) AS rn
    FROM    ema_rec
    QUALIFY rn = 1
)
/* 8. Final result ------------------------------------------------*/
SELECT  cd."titleFull"  AS full_title,
        m.cpc_group,
        m.filing_year   AS year_highest_ema
FROM    max_ema_year m
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION cd
       ON cd."symbol" = m.cpc_group
      AND cd."level"  = 4
ORDER BY m.ema DESC NULLS LAST;