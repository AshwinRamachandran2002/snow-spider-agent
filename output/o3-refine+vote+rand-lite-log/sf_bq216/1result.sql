WITH target_info AS (           /* filing year of US‑9741766‑B2 */
    SELECT 
        FLOOR(COALESCE("filing_date",
                       "priority_date",
                       "publication_date") / 10000)         AS "filing_year"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "publication_number" = 'US-9741766-B2'
    LIMIT 1
),
target_cpc4 AS (                /* 4‑digit CPC codes of the target patent */
    SELECT DISTINCT
           SUBSTR(c.value:"code"::STRING, 1, 4)              AS "cpc4"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p,
         LATERAL FLATTEN(INPUT => p."cpc")                  c
    WHERE p."publication_number" = 'US-9741766-B2'
      AND c.value:"code" IS NOT NULL
),
year_peers AS (                 /* publications filed the same year as the target */
    SELECT
        pub."publication_number",
        SUBSTR(c.value:"code"::STRING, 1, 4)                 AS "cpc4"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS pub
    JOIN target_info ti
      ON FLOOR(COALESCE(pub."filing_date",
                        pub."priority_date",
                        pub."publication_date") / 10000) = ti."filing_year"
    , LATERAL FLATTEN(INPUT => pub."cpc")                    c
    WHERE pub."publication_number" <> 'US-9741766-B2'
      AND c.value:"code" IS NOT NULL
),
overlap_score AS (             /* count of overlapping CPC‑4 codes with the target */
    SELECT
        yp."publication_number",
        COUNT(DISTINCT yp."cpc4")                            AS "overlap_cnt"
    FROM year_peers       yp
    JOIN target_cpc4      tc
      ON yp."cpc4" = tc."cpc4"
    GROUP BY yp."publication_number"
)
SELECT
    "publication_number"
FROM overlap_score
ORDER BY
    "overlap_cnt" DESC NULLS LAST,
    "publication_number"
LIMIT 5;