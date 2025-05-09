WITH target_year AS (
    /* get filing year of the focal patent */
    SELECT FLOOR("filing_date" / 10000) AS "filing_year"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "publication_number" = 'US-9741766-B2'
    LIMIT 1
),

target_vec AS (
    /* explode embedding of focal patent */
    SELECT  f.INDEX    AS "idx",
            f.VALUE::FLOAT AS "val"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB t,
         LATERAL FLATTEN(INPUT => t."embedding_v1") f
    WHERE t."publication_number" = 'US-9741766-B2'
),

candidates AS (
    /* other patents filed in the same year */
    SELECT DISTINCT p."publication_number"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p,
         target_year
    WHERE FLOOR(p."filing_date" / 10000) = target_year."filing_year"
      AND p."publication_number" <> 'US-9741766-B2'
),

cand_vec AS (
    /* explode embeddings of candidate patents */
    SELECT  c."publication_number",
            f.INDEX        AS "idx",
            f.VALUE::FLOAT AS "val"
    FROM candidates c
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
      ON a."publication_number" = c."publication_number",
         LATERAL FLATTEN(INPUT => a."embedding_v1") f
),

dot_products AS (
    /* similarity = dot product */
    SELECT  c."publication_number",
            SUM(c."val" * t."val") AS "similarity"
    FROM cand_vec c
    JOIN target_vec t
      ON c."idx" = t."idx"
    GROUP BY c."publication_number"
)

SELECT "publication_number"
FROM   dot_products
ORDER  BY "similarity" DESC NULLS LAST
LIMIT 5;