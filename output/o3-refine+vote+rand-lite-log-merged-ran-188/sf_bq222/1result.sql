WITH RECURSIVE
/*-----------------------------------------------------------
  1)  All CPC-L4 groups that appear on German patents granted
      in December-2016
-----------------------------------------------------------*/
dec16 AS (
    SELECT DISTINCT
           REGEXP_SUBSTR(f.value:"code"::STRING , '^[A-HY][0-9]{2}[A-Z]') AS "cpc_group"
    FROM PATENTS.PATENTS.PUBLICATIONS  p,
         LATERAL FLATTEN (INPUT => p."cpc") f
    WHERE p."country_code" = 'DE'
      AND p."grant_date"   BETWEEN 20161201 AND 20161231
),
/*-----------------------------------------------------------
  2)  Yearly grant counts for every German patent publication
-----------------------------------------------------------*/
yearly AS (
    SELECT
        REGEXP_SUBSTR(f.value:"code"::STRING , '^[A-HY][0-9]{2}[A-Z]') AS "cpc_group",
        TO_NUMBER(LEFT(p."grant_date",4))                              AS "grant_year",
        COUNT(*)                                                       AS "grant_count"
    FROM PATENTS.PATENTS.PUBLICATIONS  p,
         LATERAL FLATTEN (INPUT => p."cpc") f
    WHERE p."country_code" = 'DE'
    GROUP BY 1,2
),
/*-----------------------------------------------------------
  3)  Sequence index of years within each CPC group
-----------------------------------------------------------*/
ranked AS (
    SELECT
        y.*,
        ROW_NUMBER() OVER (PARTITION BY y."cpc_group"
                           ORDER BY       y."grant_year")              AS "rn"
    FROM yearly y
),
/*-----------------------------------------------------------
  4)  Recursive computation of EMA with α = 0.1
-----------------------------------------------------------*/
ema_r AS (
    -- seed (first year for each group)
    SELECT
        r."cpc_group",
        r."grant_year",
        r."grant_count",
        r."rn",
        CAST(r."grant_count" AS FLOAT)                                  AS "ema_val"
    FROM ranked r
    WHERE r."rn" = 1

    UNION ALL

    -- recursive step
    SELECT
        r."cpc_group",
        r."grant_year",
        r."grant_count",
        r."rn",
        0.1 * r."grant_count" + 0.9 * e."ema_val"                       AS "ema_val"
    FROM ema_r  e
    JOIN ranked r
      ON r."cpc_group" = e."cpc_group"
     AND r."rn"        = e."rn" + 1
),
/*-----------------------------------------------------------
  5)  Pick, for each CPC group, the year with the highest EMA
-----------------------------------------------------------*/
best AS (
    SELECT *
    FROM (
        SELECT
            "cpc_group",
            "grant_year" AS "best_year",
            "ema_val",
            ROW_NUMBER() OVER (PARTITION BY "cpc_group"
                               ORDER BY       "ema_val" DESC)          AS "rk"
        FROM ema_r
    )
    WHERE "rk" = 1
)
/*-----------------------------------------------------------
  6)  Return only the CPC groups that occur on DE patents
      granted in Dec-2016, plus their CPC definition title
-----------------------------------------------------------*/
SELECT
    b."cpc_group",
    d."titleFull"                AS "cpc_full_title",
    b."best_year",
    b."ema_val"
FROM best b
JOIN dec16 g
  ON b."cpc_group" = g."cpc_group"
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
  ON d."symbol" = b."cpc_group"
ORDER BY b."ema_val" DESC NULLS LAST;