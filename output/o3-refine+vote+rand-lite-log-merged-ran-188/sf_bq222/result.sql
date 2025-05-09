WITH RECURSIVE
/*───────────────────────── ①  Yearly counts for patents granted in Dec-2016 ─────────────────────────*/
cnt AS (
    SELECT
        FLOOR(p."publication_date" / 10000)                       AS "pub_year",
        SUBSTR(c.value::VARIANT:"code"::STRING, 1, 4)             AS "cpc_group",
        COUNT(*)                                                  AS "filing_cnt"
    FROM   PATENTS.PATENTS.PUBLICATIONS  p,
           LATERAL FLATTEN (INPUT => p."cpc")                    c
    WHERE  p."country_code" = 'DE'
      AND  p."grant_date" BETWEEN 20161201 AND 20161231           -- granted in Dec-2016
      AND  SUBSTR(c.value::VARIANT:"code"::STRING, 1, 4) IS NOT NULL
    GROUP  BY FLOOR(p."publication_date" / 10000),
              SUBSTR(c.value::VARIANT:"code"::STRING, 1, 4)
),
/*───────────────────────── ②  Sequence numbers inside each CPC group ─────────────────────────*/
seq AS (
    SELECT
        "cpc_group",
        "pub_year",
        "filing_cnt",
        ROW_NUMBER() OVER (PARTITION BY "cpc_group" ORDER BY "pub_year") AS "rn"
    FROM  cnt
),
/*───────────────────────── ③  Recursive EMA with α = 0.1 ─────────────────────────*/
ema ("cpc_group","pub_year","filing_cnt","ema","rn") AS (
    SELECT  s."cpc_group",
            s."pub_year",
            s."filing_cnt",
            s."filing_cnt"::FLOAT                    AS "ema",
            s."rn"
    FROM    seq s
    WHERE   s."rn" = 1
    UNION ALL
    SELECT  s."cpc_group",
            s."pub_year",
            s."filing_cnt",
            0.1 * s."filing_cnt" + 0.9 * e."ema"     AS "ema",
            s."rn"
    FROM    ema e
    JOIN    seq s
           ON s."cpc_group" = e."cpc_group"
          AND s."rn"        = e."rn" + 1
),
/*───────────────────────── ④  Best EMA year/value for each CPC-L4 group ─────────────────────────*/
best AS (
    SELECT
        "cpc_group",
        MAX_BY("pub_year","ema")   AS "best_year",
        MAX("ema")                 AS "max_ema"
    FROM   ema
    GROUP  BY "cpc_group"
)
/*───────────────────────── ⑤  Attach CPC title & output ─────────────────────────*/
SELECT
    d."titleFull"      AS "cpc_title",
    b."cpc_group",
    b."best_year",
    b."max_ema"
FROM   best b
LEFT  JOIN PATENTS.PATENTS.CPC_DEFINITION d
       ON d."symbol" = b."cpc_group"
ORDER  BY b."max_ema" DESC NULLS LAST;