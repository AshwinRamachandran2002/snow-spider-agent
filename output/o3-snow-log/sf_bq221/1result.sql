/* -----------------------------------------------------------
   Identify CPC level-5 technology areas with the highest
   exponential moving average (α = 0.2) of yearly filings.
------------------------------------------------------------*/
WITH RECURSIVE
/* Step-1 & 2 : yearly filing counts per CPC level-5 group */
yearly_counts AS (
    SELECT
        SUBSTR( f.value:"code"::STRING , 1 , 4 )  AS subclass ,               -- CPC level-5 (e.g. H04L)
        FLOOR( p."filing_date" / 10000 )          AS year ,                   -- YYYY from YYYYMMDD
        COUNT( DISTINCT p."publication_number" )  AS filings
    FROM PATENTS.PATENTS.PUBLICATIONS  AS p
         , LATERAL FLATTEN( INPUT => p."cpc" ) AS f
    WHERE f."INDEX" = 0                    -- use only the first CPC code
      AND p."application_number" <> ''
      AND p."filing_date" IS NOT NULL
      AND p."filing_date" <> 0
    GROUP BY subclass , year
),

/* Step-3 : add row numbers per subclass to order years */
ordered_counts AS (
    SELECT
        subclass ,
        year ,
        filings ,
        ROW_NUMBER() OVER ( PARTITION BY subclass ORDER BY year ) AS rn
    FROM yearly_counts
),

/* Step-4 : recursive EMA computation (α = 0.2)                */
ema_calc AS (
    /* anchor rows – first year per subclass */
    SELECT
        subclass ,
        year ,
        filings ,
        CAST(filings AS FLOAT)                AS ema ,   -- EMA₀ = value₀
        rn
    FROM ordered_counts
    WHERE rn = 1

    UNION ALL

    /* recursive rows – follow-up years */
    SELECT
        o.subclass ,
        o.year ,
        o.filings ,
        0.2 * o.filings + 0.8 * e.ema         AS ema ,
        o.rn
    FROM ordered_counts AS o
    JOIN ema_calc     AS e
      ON  o.subclass = e.subclass
     AND  o.rn       = e.rn + 1               -- next chronological year
),

/* Step-5 : pick the year with maximum EMA per subclass        */
best_years AS (
    SELECT
        subclass ,
        year        AS best_year ,
        ema         AS max_ema ,
        ROW_NUMBER() OVER ( PARTITION BY subclass ORDER BY ema DESC ) AS rk
    FROM ema_calc
)

/* Step-6 : attach CPC titles and return results               */
SELECT
    b.subclass                                AS "cpc_group",
    d."titleFull"                             AS "cpc_title",
    b.best_year                               AS "best_year",
    b.max_ema                                 AS "highest_ema"
FROM best_years AS b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION AS d
       ON d."symbol" = b.subclass
      AND d."level"  = 5
WHERE b.rk = 1                                -- keep row with highest EMA
ORDER BY b.max_ema DESC NULLS LAST;