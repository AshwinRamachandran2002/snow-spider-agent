/*--------------------------------------------------------------
  Identify, for every level-5 CPC technology area, the year in
  which the exponential-moving-average (α = 0.2) of patent
  filings is maximal, and show the CPC full title.
----------------------------------------------------------------*/
WITH publication_cpc AS (      -- keep only the 1st CPC code
    SELECT
        SUBSTR(f.value:"code"::STRING, 1, 5)  AS cpc_group ,
        FLOOR(p."filing_date" / 10000)        AS filing_year
    FROM PATENTS.PATENTS.PUBLICATIONS  p ,
         LATERAL FLATTEN (INPUT => p."cpc") f
    WHERE f.index = 0
      AND p."application_number" IS NOT NULL
      AND p."application_number" <> ''
      AND p."filing_date" > 0
),
yearly_counts AS (              -- filings per CPC group & year
    SELECT
        cpc_group ,
        filing_year ,
        COUNT(*) AS num_filings
    FROM publication_cpc
    GROUP BY cpc_group , filing_year
),
prep AS (                       -- add an ordinal “t” per group
    SELECT
        cpc_group ,
        filing_year ,
        num_filings ,
        ROW_NUMBER() OVER (PARTITION BY cpc_group
                           ORDER BY filing_year) - 1 AS t
    FROM yearly_counts
),
--  Exponential moving average (EMA) with α = 0.2
ema_calc AS (
    SELECT
        p1.cpc_group ,
        p1.filing_year ,
        SUM( p2.num_filings * POWER(1 - 0.2 , p1.t - p2.t) ) AS weighted_sum ,
        SUM( POWER(1 - 0.2 , p1.t - p2.t) )                  AS weight_div
    FROM prep p1
    JOIN prep p2
      ON p1.cpc_group = p2.cpc_group
     AND p2.t        <= p1.t
    GROUP BY p1.cpc_group , p1.filing_year , p1.t
),
ema AS (                        -- actual EMA value
    SELECT
        cpc_group ,
        filing_year ,
        weighted_sum / NULLIF(weight_div , 0) AS ema_value
    FROM ema_calc
),
best_year_per_group AS (        -- year with highest EMA in group
    SELECT
        cpc_group ,
        filing_year  AS best_year ,
        ema_value    AS best_ema ,
        ROW_NUMBER() OVER (
            PARTITION BY cpc_group
            ORDER BY best_ema DESC , filing_year
        ) AS rn
    FROM ema
),
selected_best AS (
    SELECT cpc_group , best_year , best_ema
    FROM   best_year_per_group
    WHERE  rn = 1
),
--  Choose one descriptive title for each level-5 CPC group
cpc_title_choice AS (
    SELECT
        SUBSTR(cd."symbol" , 1 , 5)           AS cpc_group ,
        cd."titleFull"                        AS title_full ,
        ROW_NUMBER() OVER (
            PARTITION BY SUBSTR(cd."symbol" , 1 , 5)
            ORDER BY LENGTH(cd."symbol") , cd."symbol"
        ) AS rn
    FROM PATENTS.PATENTS.CPC_DEFINITION cd
),
cpc_titles AS (
    SELECT cpc_group , title_full
    FROM   cpc_title_choice
    WHERE  rn = 1
)
SELECT
    b.cpc_group          AS "cpc_group_lvl5" ,
    t.title_full         AS "cpc_full_title" ,
    b.best_year          AS "best_year" ,
    ROUND(b.best_ema , 2) AS "highest_ema"
FROM selected_best b
LEFT JOIN cpc_titles t
       ON t.cpc_group = b.cpc_group
ORDER BY b.best_ema DESC NULLS LAST;