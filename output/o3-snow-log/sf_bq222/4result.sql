/*  Highest-EMA CPC (level-4) technology areas for German patents
    granted in December-2016                                         */

WITH RECURSIVE
/*---------------------------------------------------------------*/
filtered AS (      -- German patents granted in Dec-2016
    SELECT  "publication_number",
            "filing_date",
            "cpc"
    FROM    PATENTS.PATENTS.PUBLICATIONS
    WHERE   "country_code" = 'DE'
      AND   "grant_date" BETWEEN 20161201 AND 20161231
      AND   "filing_date" IS NOT NULL
),
/*---------------------------------------------------------------*/
cpc_expanded AS (  -- explode CPC and keep 4-char group
    SELECT  DISTINCT
            f."publication_number",
            f."filing_date",
            SUBSTR( fct.value :code ::STRING , 1 , 4 ) AS cpc_group
    FROM    filtered f,
            LATERAL FLATTEN( INPUT => f."cpc" ) AS fct
    WHERE   fct.value :code IS NOT NULL
),
/*---------------------------------------------------------------*/
yearly_counts AS ( -- filings per CPC-group per year
    SELECT  cpc_group,
            CAST( FLOOR( "filing_date" / 10000 ) AS INT ) AS yr,
            COUNT( DISTINCT "publication_number")        AS filings
    FROM    cpc_expanded
    GROUP BY cpc_group, yr
),
/*---------------------------------------------------------------*/
ordered AS (       -- add row index within each group
    SELECT  cpc_group,
            yr,
            filings,
            ROW_NUMBER() OVER (PARTITION BY cpc_group ORDER BY yr) AS rn
    FROM    yearly_counts
),
/*---------------------------------------------------------------*/
ema_cte (cpc_group, yr, filings, ema, rn) AS (  -- recursive EMA
    /* seed */
    SELECT  cpc_group, yr, filings,
            filings AS ema,
            rn
    FROM    ordered
    WHERE   rn = 1

    UNION ALL

    /* recursion */
    SELECT  o.cpc_group,
            o.yr,
            o.filings,
            0.1 * o.filings + 0.9 * e.ema  AS ema,
            o.rn
    FROM    ema_cte e
    JOIN    ordered o
           ON  o.cpc_group = e.cpc_group
           AND o.rn        = e.rn + 1
),
/*---------------------------------------------------------------*/
best_year AS (     -- year with highest EMA for each group
    SELECT  cpc_group,
            yr   AS year_highest_ema,
            ema,
            ROW_NUMBER() OVER (PARTITION BY cpc_group
                               ORDER BY ema DESC, yr) AS rnk
    FROM    ema_cte
    QUALIFY rnk = 1
)
/*---------------------------------------------------------------*/
SELECT  cd."titleFull"      AS full_title,
        b.cpc_group         AS cpc_group,
        b.year_highest_ema  AS year_highest_ema
FROM    best_year  b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION cd
       ON cd."symbol" = UPPER(b.cpc_group)
ORDER BY b.cpc_group;