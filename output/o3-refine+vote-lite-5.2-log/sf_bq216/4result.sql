/*  Top‑5 patents filed in the same year as US‑9741766‑B2
    ranked by the number of shared 4‑digit CPC codes (technological similarity)  */

WITH base_pub AS (                 -- reference patent record
    SELECT
        "publication_number",
        "cpc",
        COALESCE(
            NULLIF("filing_date"     ,0),
            NULLIF("priority_date"   ,0),
            NULLIF("publication_date",0)
        )                   AS ref_date
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "publication_number" = 'US-9741766-B2'
    LIMIT 1
),
base_year AS (                     -- filing (or best available) year
    SELECT FLOOR(ref_date/10000) AS yr
    FROM base_pub
),
base_cpc4 AS (                     -- distinct 4‑digit CPCs of the reference patent
    SELECT DISTINCT
           SUBSTR(f.value:"code"::STRING,1,4) AS cpc4
    FROM base_pub,
         LATERAL FLATTEN(INPUT => "cpc") f
    WHERE f.value:"code" IS NOT NULL
),
cands AS (                         -- candidate patents filed in the same year
    SELECT
        p."publication_number",
        p."cpc"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN base_year y
         ON FLOOR(
                COALESCE(
                    NULLIF(p."filing_date"     ,0),
                    NULLIF(p."priority_date"   ,0),
                    NULLIF(p."publication_date",0)
                ) / 10000
            ) = y.yr
    WHERE p."publication_number" <> 'US-9741766-B2'
      AND p."cpc" IS NOT NULL
),
cand_cpc4 AS (                     -- explode candidate CPCs
    SELECT
        c."publication_number",
        SUBSTR(f.value:"code"::STRING,1,4) AS cpc4
    FROM cands c,
         LATERAL FLATTEN(INPUT => c."cpc") f
    WHERE f.value:"code" IS NOT NULL
),
shared AS (                        -- intersection size with the base CPC set
    SELECT
        cc."publication_number",
        COUNT(DISTINCT cc.cpc4) AS shared_cpc4_cnt
    FROM cand_cpc4 cc
    JOIN base_cpc4 bc
      ON cc.cpc4 = bc.cpc4
    GROUP BY cc."publication_number"
)
SELECT
    "publication_number"
FROM shared
ORDER BY
    shared_cpc4_cnt DESC NULLS LAST,
    "publication_number"
LIMIT 5;