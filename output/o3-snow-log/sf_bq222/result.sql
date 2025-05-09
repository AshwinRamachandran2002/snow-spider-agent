/*  German patents granted in December 2016.
    For every CPC level-4 group appearing in those patents,
    compute the exponential moving average (α = 0.1) of yearly
    filing counts and report the year where that EMA peaks.      */

WITH RECURSIVE
/* 1.  Patents granted in Germany in Dec-2016 -------------------*/
dec16_grants AS (
    SELECT  p."publication_number",
            TRY_TO_DATE(p."filing_date"::STRING , 'YYYYMMDD') AS filing_dt,
            p."cpc"
    FROM    PATENTS.PATENTS.PUBLICATIONS p
    WHERE   p."country_code" = 'DE'
      AND   p."grant_date"   BETWEEN 20161201 AND 20161231
      AND   p."cpc" IS NOT NULL
      AND   p."filing_date" IS NOT NULL
),
/* 2.  Explode CPC list and cut back to level-4 symbol ----------*/
lvl4_codes AS (
    SELECT  g."publication_number",
            YEAR(g.filing_dt)                                          AS filing_year,
            REGEXP_SUBSTR(f.value:"code"::STRING , '^[A-Z]\\d{2}[A-Z]') AS cpc_grp
    FROM    dec16_grants g,
            LATERAL FLATTEN(input => g."cpc") f
    WHERE   f.value:"code" IS NOT NULL
      AND   REGEXP_SUBSTR(f.value:"code"::STRING , '^[A-Z]\\d{2}[A-Z]') IS NOT NULL
),
/* 3.  Yearly filing counts per CPC-group -----------------------*/
year_counts AS (
    SELECT  cpc_grp                            AS grp,
            filing_year                        AS yr,
            COUNT(*)                           AS filings
    FROM    lvl4_codes
    GROUP BY grp, yr
),
/* 4.  Sequence rows per group for recursive EMA ----------------*/
ordered AS (
    SELECT  grp,
            yr,
            filings,
            ROW_NUMBER() OVER (PARTITION BY grp ORDER BY yr) AS rn
    FROM    year_counts
),
/* 5.  Recursive EMA (α = 0.1) ---------------------------------*/
ema AS (
    /* anchor row ------------------------------------------------*/
    SELECT  grp, yr, filings,
            filings * 0.1                  AS ema,
            rn
    FROM    ordered
    WHERE   rn = 1
    UNION ALL
    /* recursion -------------------------------------------------*/
    SELECT  o.grp,
            o.yr,
            o.filings,
            (o.filings * 0.1) + (e.ema * 0.9) AS ema,
            o.rn
    FROM    ordered o
    JOIN    ema     e
          ON o.grp = e.grp
         AND o.rn  = e.rn + 1
),
/* 6.  Select year with highest EMA for each group --------------*/
peak_ema AS (
    SELECT  grp,
            yr                 AS peak_year,
            ema,
            ROW_NUMBER() OVER (PARTITION BY grp ORDER BY ema DESC, yr) AS rk
    FROM    ema
)
/* 7.  Attach CPC definitions (if available) and present result  */
SELECT  COALESCE(d."titleFull", '(title unavailable)') AS cpc_title,
        p.grp                                         AS cpc_group,
        p.peak_year                                   AS year_of_peak_ema
FROM    peak_ema               p
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
       ON d."symbol" = p.grp
WHERE   p.rk = 1
ORDER BY p.ema DESC NULLS LAST;