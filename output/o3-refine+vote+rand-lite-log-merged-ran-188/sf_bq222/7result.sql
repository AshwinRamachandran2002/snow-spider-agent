/*---------------------------------------------------------------
   For every CPC subclass that occurs on German patents granted
   in December-2016, determine the calendar-year in which its
   exponential moving average (α = 0.1) of yearly grant counts
   attains its maximum.
----------------------------------------------------------------*/
WITH RECURSIVE

/*-- 1) subclasses that appear on German patents granted Dec-2016 --*/
dec16_subclasses AS (
    SELECT DISTINCT
           SUBSTR(c.value:"code"::STRING, 1, 4) AS subclass_code
    FROM   PATENTS.PATENTS.PUBLICATIONS p,
           LATERAL FLATTEN(input => p."cpc") c
    WHERE  p."country_code" = 'DE'
      AND  p."grant_date"   BETWEEN 20161201 AND 20161231
),

/*----------- 2) yearly grant counts for those subclasses --------*/
yearly_counts AS (
    SELECT
        SUBSTR(c.value:"code"::STRING, 1, 4) AS subclass_code,
        FLOOR(p."grant_date" / 10000)        AS year,
        COUNT(*)                             AS patent_count
    FROM   PATENTS.PATENTS.PUBLICATIONS p,
           LATERAL FLATTEN(input => p."cpc") c
    WHERE  p."country_code" = 'DE'
      AND  SUBSTR(c.value:"code"::STRING, 1, 4)
           IN (SELECT subclass_code FROM dec16_subclasses)
    GROUP  BY subclass_code, year
),

/*--- 3) chronological ordering of counts within each subclass ---*/
ordered_counts AS (
    SELECT
        subclass_code,
        year,
        patent_count,
        ROW_NUMBER() OVER (PARTITION BY subclass_code
                           ORDER BY year) AS rn
    FROM   yearly_counts
),

/*-------------- 4) recursive EMA calculation -------------------*/
ema_calc AS (
    /* anchor row : first year per subclass */
    SELECT
        subclass_code,
        year,
        patent_count,
        patent_count * 0.1                   AS ema_value,
        rn
    FROM   ordered_counts
    WHERE  rn = 1

    UNION ALL

    /* recursive rows */
    SELECT
        oc.subclass_code,
        oc.year,
        oc.patent_count,
        0.1 * oc.patent_count + 0.9 * ec.ema_value AS ema_value,
        oc.rn
    FROM   ordered_counts oc
    JOIN   ema_calc      ec
      ON   oc.subclass_code = ec.subclass_code
     AND   oc.rn          = ec.rn + 1
),

/*----------- 5) select the year with the highest EMA ------------*/
best_years AS (
    SELECT
        subclass_code,
        year        AS best_year,
        ema_value,
        ROW_NUMBER() OVER (PARTITION BY subclass_code
                           ORDER BY ema_value DESC) AS rnk
    FROM   ema_calc
    QUALIFY rnk = 1           -- keep only the maximum-EMA year
)

/*------------------------- 6) output ---------------------------*/
SELECT
    COALESCE(d."titleFull", 'N/A')  AS "cpc_title",
    b.subclass_code                 AS "cpc_group",
    b.best_year                     AS "year_with_highest_ema"
FROM   best_years                 b
LEFT  JOIN PATENTS.PATENTS.CPC_DEFINITION d
       ON d."symbol" = b.subclass_code   -- title for the subclass
ORDER  BY b.ema_value DESC NULLS LAST;