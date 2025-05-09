/*  Level‑4 CPC technology areas represented in patents that were granted
    in Germany during December 2016.  For every CPC area we calculate the
    yearly filing counts of German patent applications, smooth them with an
    exponential moving average (α = 0.1), and return the year in which that
    average is highest.                                                   */

WITH RECURSIVE
/* --------------------------------------------------------------------- */
/* 1.  CPC prefixes (text before the “/”) that occur in DE patents whose
       grant date lies in December‑2016                                   */
cpc_prefixes AS (
    SELECT DISTINCT
           UPPER(SPLIT_PART(c.value:"code"::STRING, '/', 1))    AS cpc_prefix
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc") c
    WHERE p."country_code" = 'DE'
      AND p."grant_date" BETWEEN 20161201 AND 20161231
      AND c.value:"code" IS NOT NULL
),

/* --------------------------------------------------------------------- */
/* 2.  Annual filing counts for those prefixes (all years)                */
annual_counts AS (
    SELECT
        cp.cpc_prefix,
        FLOOR(p."filing_date" / 10000)                         AS yr,       -- filing year
        COUNT(DISTINCT p."publication_number")                 AS filings
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc") c
         JOIN cpc_prefixes cp
           ON cp.cpc_prefix = UPPER(SPLIT_PART(c.value:"code"::STRING, '/', 1))
    WHERE p."country_code" = 'DE'
      AND p."filing_date" > 0
      AND c.value:"code" IS NOT NULL
    GROUP BY cp.cpc_prefix, yr
),

/* --------------------------------------------------------------------- */
/* 3.  Chronological order inside every CPC prefix                        */
ordered AS (
    SELECT
        cpc_prefix,
        yr,
        filings,
        ROW_NUMBER() OVER (PARTITION BY cpc_prefix ORDER BY yr) AS rn
    FROM annual_counts
),

/* --------------------------------------------------------------------- */
/* 4.  Recursive calculation of the EMA  ( α = 0.1 )                     */
ema_series AS (
    /* seed row (first year per prefix) */
    SELECT
        cpc_prefix,
        yr,
        filings,
        rn,
        CAST(filings AS FLOAT)                              AS ema
    FROM ordered
    WHERE rn = 1

    UNION ALL

    /* recursive rows                                                   */
    SELECT
        o.cpc_prefix,
        o.yr,
        o.filings,
        o.rn,
        0.1 * o.filings + 0.9 * r.ema                       AS ema
    FROM ordered      o
    JOIN ema_series   r
      ON o.cpc_prefix = r.cpc_prefix
     AND o.rn        = r.rn + 1
),

/* --------------------------------------------------------------------- */
/* 5.  For every prefix, keep the year where EMA is maximal               */
best_year AS (
    SELECT
        cpc_prefix,
        yr                               AS best_year,
        ema,
        ROW_NUMBER() OVER (PARTITION BY cpc_prefix
                           ORDER BY ema DESC, yr)            AS rnk
    FROM ema_series
    QUALIFY rnk = 1
),

/* --------------------------------------------------------------------- */
/* 6.  Map every prefix to one level‑4 CPC group and its full title       */
lvl4_map AS (
    SELECT
        SPLIT_PART(d."symbol", '/', 1)   AS cpc_prefix,
        d."symbol"                       AS cpc_group,
        d."titleFull"                    AS full_title,
        ROW_NUMBER() OVER (PARTITION BY SPLIT_PART(d."symbol", '/', 1)
                           ORDER BY d."symbol")              AS pick
    FROM PATENTS.PATENTS.CPC_DEFINITION d
    WHERE d."level" = 4
)
/* --------------------------------------------------------------------- */
SELECT
    m.full_title                         AS "full_title",
    m.cpc_group                          AS "cpc_group",
    b.best_year                          AS "year_with_highest_ema"
FROM best_year        b
LEFT JOIN lvl4_map    m
       ON m.cpc_prefix = b.cpc_prefix
      AND m.pick = 1                     -- one representative per prefix
ORDER BY "year_with_highest_ema" NULLS LAST,
         "cpc_group";