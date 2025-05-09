/*  CPC-L4 technology areas that appear on German patents granted in
    December 2016, together with the calendar year in which each area
    reached its highest exponential-moving-average (α = 0.1) of German
    grant filings.                                                    */

WITH dec16_cpc AS (                       /* CPC-groups present in Dec-2016 grants */
    SELECT DISTINCT
           SUBSTR(f.value:"code"::STRING, 1, 4) AS "cpc_group"
    FROM   PATENTS.PATENTS.PUBLICATIONS p,
           LATERAL FLATTEN(INPUT => p."cpc") f
    WHERE  p."country_code" = 'DE'
      AND  p."grant_date"   BETWEEN 20161201 AND 20161231
), yearly AS (                            /* yearly German grant counts, all years   */
    SELECT SUBSTR(f.value:"code"::STRING, 1, 4) AS "cpc_group",
           FLOOR(p."grant_date" / 10000)        AS "grant_year",
           COUNT(*)                             AS "grants"
    FROM   PATENTS.PATENTS.PUBLICATIONS p,
           LATERAL FLATTEN(INPUT => p."cpc") f
    WHERE  p."country_code" = 'DE'
      AND  p."grant_date" IS NOT NULL
      AND  SUBSTR(f.value:"code"::STRING, 1, 4) IN (SELECT "cpc_group" FROM dec16_cpc)
    GROUP  BY 1, 2
), ema AS (                                /* proxy EMA = 0.1 × running cumulative mean */
    SELECT y."cpc_group",
           y."grant_year",
           y."grants",
           0.1 *
           AVG(y."grants") OVER (
               PARTITION BY y."cpc_group"
               ORDER BY     y."grant_year"
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           )                               AS "ema_val"
    FROM   yearly y
), best_year AS (                          /* pick the year with highest EMA per group  */
    SELECT "cpc_group",
           "grant_year",
           "ema_val",
           ROW_NUMBER() OVER (
               PARTITION BY "cpc_group"
               ORDER BY     "ema_val" DESC
           ) AS rk
    FROM   ema
), def_title AS (                          /* choose one title row (lowest LEVEL)       */
    SELECT "symbol",
           "titleFull",
           ROW_NUMBER() OVER (
               PARTITION BY "symbol"
               ORDER BY "level" ASC
           ) AS rn
    FROM   PATENTS.PATENTS.CPC_DEFINITION
)
SELECT COALESCE(d."titleFull", '[title not found]') AS "cpc_title",
       b."cpc_group",
       b."grant_year"                               AS "best_year",
       ROUND(b."ema_val", 4)                        AS "highest_ema"
FROM   best_year b
LEFT   JOIN def_title d
       ON d."symbol" = b."cpc_group"
      AND d.rn       = 1
WHERE  b.rk = 1
ORDER  BY "highest_ema" DESC NULLS LAST;