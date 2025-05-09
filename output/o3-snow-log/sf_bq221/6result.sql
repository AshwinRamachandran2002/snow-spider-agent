/* -------------------------------------------------
   Highest exponential-moving-average (α = 0.20) of
   yearly patent-filing counts for each CPC level-5
   group, based on the *first* CPC code of every
   publication with a valid filing date & application
   number.
--------------------------------------------------*/
WITH RECURSIVE
/* 1) First CPC code per publication having good data */
first_cpc AS (
    SELECT  p."publication_number"                              AS pub_num,
            FLOOR(p."filing_date" / 10000)                      AS filing_year,
            SUBSTR(f.value:"code"::STRING, 1, 4)                AS subclass_code,   -- e.g. H01L
            ROW_NUMBER() OVER (PARTITION BY p."publication_number"
                               ORDER BY f.seq)                  AS rn_in_pub
    FROM PATENTS.PATENTS.PUBLICATIONS p
         ,LATERAL FLATTEN(INPUT => p."cpc") f
    WHERE p."application_number" IS NOT NULL
      AND p."application_number" <> ''
      AND p."filing_date" IS NOT NULL
),
/* 2) Keep only that first CPC row and discard bad years */
first_only AS (
    SELECT  pub_num,
            filing_year,
            subclass_code
    FROM    first_cpc
    WHERE   rn_in_pub = 1
      AND   filing_year > 0
),
/* 3) Yearly filing counts per CPC subclass */
annual_filings AS (
    SELECT  subclass_code,
            filing_year,
            COUNT(*) AS filings
    FROM    first_only
    GROUP BY subclass_code, filing_year
),
/* 4) Order years for each subclass */
ordered AS (
    SELECT  subclass_code,
            filing_year,
            filings,
            ROW_NUMBER() OVER (PARTITION BY subclass_code
                               ORDER BY filing_year) AS rn
    FROM    annual_filings
),
/* 5) Recursive EMA calculation (seed = first year's count) */
ema_cte AS (
    /* anchor */
    SELECT  subclass_code,
            filing_year,
            filings,
            CAST(filings AS FLOAT) AS ema,
            rn
    FROM    ordered
    WHERE   rn = 1
    UNION ALL
    /* recursive step */
    SELECT  o.subclass_code,
            o.filing_year,
            o.filings,
            0.20 * o.filings + 0.80 * r.ema      AS ema,
            o.rn
    FROM    ema_cte r
            JOIN ordered o
              ON  o.subclass_code = r.subclass_code
             AND o.rn            = r.rn + 1
),
/* 6) Best year (highest EMA) per subclass */
best_year_per_cpc AS (
    SELECT  subclass_code,
            filing_year  AS best_year,
            ema          AS highest_ema
    FROM    ema_cte
    QUALIFY ROW_NUMBER() OVER (PARTITION BY subclass_code
                               ORDER BY ema DESC NULLS LAST) = 1
)
/* 7) Final output with CPC titles */
SELECT  d."symbol"     AS cpc_level5,
        d."titleFull"  AS cpc_title,
        b.best_year,
        ROUND(b.highest_ema, 4) AS highest_ema
FROM    best_year_per_cpc b
JOIN    PATENTS.PATENTS.CPC_DEFINITION d
       ON d."symbol" = b.subclass_code
WHERE   d."level" = 5
ORDER BY b.highest_ema DESC NULLS LAST;