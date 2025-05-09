/* -----------------------------------------------------------------
   Further-optimised query
   – Flattens ONLY those citation arrays that actually mention one
     of our 2010-2014 US-B2 utility patents (“candidates”).  This
     drastic early filter keeps the job well under the 200-second
     limit.
-------------------------------------------------------------------*/
WITH
/* ----------  B2 utility patents granted 2010-2014 -------------- */
candidates AS (
    SELECT
        p."publication_number",
        p."filing_date"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    WHERE p."country_code"     = 'US'
      AND p."kind_code"        = 'B2'
      AND p."application_kind" = 'A'
      AND p."grant_date" BETWEEN 20100101 AND 20141231
),

/* ----------  Citing patents filed 1980-01-01 … 2015-01-31 ------- */
citing_subset AS (
    SELECT
        "publication_number",
        "filing_date",
        "citation"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "filing_date" BETWEEN 19800101 AND 20150131
),

/* ----------  Flatten only citations that point to candidates --- */
citations AS (
    SELECT
        cs."publication_number"                  AS citing_pub,
        cs."filing_date"                         AS citing_file,
        cited.value:"publication_number"::STRING AS cited_pub
    FROM citing_subset cs,
         LATERAL FLATTEN(INPUT => cs."citation") cited
    WHERE cited.value:"publication_number" IS NOT NULL
      AND cited.value:"publication_number"::STRING
          IN (SELECT "publication_number" FROM candidates)
),

/* ----------  Count forward citations within 30 days ------------ */
fw_counts AS (
    SELECT
        cand."publication_number"    AS focal_pub,
        COUNT(*)                     AS fw_cites_30d
    FROM       candidates cand
    JOIN       citations  ct
           ON  ct.cited_pub = cand."publication_number"
    WHERE      ct.citing_file BETWEEN cand."filing_date"
                                  AND cand."filing_date" + 30
    GROUP BY   cand."publication_number"
),

/* ----------  The single focal patent with the highest count ---- */
top_focal AS (
    SELECT focal_pub, fw_cites_30d
    FROM   fw_counts
    ORDER  BY fw_cites_30d DESC NULLS LAST, focal_pub
    LIMIT  1
),

/* ----------  Focal patent’s filing year ------------------------ */
focal_info AS (
    SELECT
        p."publication_number"            AS focal_pub,
        FLOOR(p."filing_date" / 10000)    AS file_year
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN top_focal t ON t.focal_pub = p."publication_number"
),

/* ----------  Google-pre-computed neighbours of focal patent ---- */
neighbours AS (
    SELECT
        sn.value:"publication_number"::STRING   AS peer_pub,
        ROW_NUMBER() OVER (ORDER BY sn.index)   AS rn
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a,
         LATERAL FLATTEN(INPUT => a."similar") sn
    WHERE a."publication_number" = (SELECT focal_pub FROM focal_info)
),

/* ----------  First neighbour filed in the same year ------------ */
best_peer AS (
    SELECT n.peer_pub
    FROM   neighbours n
    JOIN   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
           ON p."publication_number" = n.peer_pub
    WHERE  FLOOR(p."filing_date" / 10000) = (SELECT file_year FROM focal_info)
    ORDER  BY n.rn
    LIMIT 1
)

/* --------------------  Final result ---------------------------- */
SELECT
    tf.focal_pub           AS "focal_publication",
    tf.fw_cites_30d        AS "fw_citations_within_30d",
    bp.peer_pub            AS "most_similar_same_year"
FROM top_focal tf
LEFT JOIN best_peer bp ON TRUE;