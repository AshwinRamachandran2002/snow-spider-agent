/* ---------------------------------------------------------------
   Find all CPC subclasses (first 4 characters of the CPC code,
   i.e. level‑4) that appear in German patents granted in
   December‑2016.  For each of those subclasses, calculate the
   yearly filing counts for ALL German patents belonging to that
   subclass, build an exponential moving average (α = 0.1) over
   the years, and return the year in which the EMA is highest.
   --------------------------------------------------------------- */
WITH RECURSIVE

/* 1. German patents granted in December‑2016 ----------------------*/
dec2016_pub AS (
    SELECT "publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS
    WHERE  "country_code" = 'DE'
      AND  "grant_date"   BETWEEN 20161201 AND 20161231
),

/* 2. CPC subclasses (4‑char) that occur in those patents ----------*/
dec2016_groups AS (
    SELECT DISTINCT
           SUBSTR(UPPER(f.value:"code"::STRING), 1, 4) AS cpc_group
    FROM   PATENTS.PATENTS.PUBLICATIONS  p
           JOIN dec2016_pub dp
             ON dp."publication_number" = p."publication_number",
         LATERAL FLATTEN(INPUT => p."cpc") f
),

/* 3. Annual filing counts for ALL German patents, restricted
      to those subclasses only ------------------------------------*/
filings_per_year AS (
    SELECT dg.cpc_group,
           FLOOR(p."filing_date" / 10000)              AS yr,
           COUNT(DISTINCT p."publication_number")      AS filings
    FROM   PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(INPUT => p."cpc") f
           JOIN dec2016_groups dg
             ON SUBSTR(UPPER(f.value:"code"::STRING),1,4) = dg.cpc_group
    WHERE  p."country_code" = 'DE'
      AND  p."filing_date" IS NOT NULL
    GROUP BY dg.cpc_group,
             FLOOR(p."filing_date" / 10000)
),

/* 4. Row numbers per subclass to drive recursive EMA --------------*/
filings_ranked AS (
    SELECT cpc_group,
           yr,
           filings,
           ROW_NUMBER() OVER (PARTITION BY cpc_group ORDER BY yr) AS rn
    FROM   filings_per_year
),

/* 5. Recursive EMA computation (α = 0.1) --------------------------*/
ema_calc (cpc_group, yr, filings, ema, rn) AS (
      /* anchor: first year */
      SELECT cpc_group,
             yr,
             filings,
             filings                           AS ema,
             rn
      FROM   filings_ranked
      WHERE  rn = 1

      UNION ALL

      /* recursive: later years */
      SELECT fr.cpc_group,
             fr.yr,
             fr.filings,
             0.1 * fr.filings + 0.9 * ec.ema  AS ema,
             fr.rn
      FROM   ema_calc        ec
             JOIN filings_ranked fr
               ON fr.cpc_group = ec.cpc_group
              AND fr.rn        = ec.rn + 1
),

/* 6. Best‑EMA year for each subclass ------------------------------*/
best_years AS (
    SELECT cpc_group,
           yr AS best_year
    FROM (
        SELECT cpc_group,
               yr,
               ema,
               ROW_NUMBER() OVER (PARTITION BY cpc_group
                                  ORDER BY ema DESC, yr DESC) AS rnk
        FROM   ema_calc
    )
    WHERE rnk = 1
)

/* 7. Final result with CPC titles --------------------------------*/
SELECT cd."titleFull"            AS "full_title",
       b.cpc_group               AS "cpc_group",
       b.best_year               AS "year_with_highest_ema"
FROM   best_years b
       LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION cd
              ON cd."symbol" = b.cpc_group
             AND cd."level"  = 4
ORDER BY b.cpc_group;