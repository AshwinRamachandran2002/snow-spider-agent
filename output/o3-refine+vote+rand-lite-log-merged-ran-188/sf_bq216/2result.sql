/*  Top‑5 patents filed in the same year as US‑9741766‑B2
    that share the largest number of 4‑digit IPC codes          */
WITH target_info AS (   /* filing year of US‑9741766‑B2 */
    SELECT FLOOR("filing_date" / 10000) AS "filing_year"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"
    WHERE "publication_number" = 'US-9741766-B2'
),

/* 4‑digit IPC codes of the target patent */
target_ipc4 AS (
    SELECT DISTINCT
           SUBSTR(ipc_u.value:"code"::STRING, 1, 4) AS "ipc4"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" tp,
         LATERAL FLATTEN(input => tp."ipc") ipc_u
    WHERE tp."publication_number" = 'US-9741766-B2'
),

/* all other patents filed in the same year */
same_year_pubs AS (
    SELECT
        p."publication_number"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" p
    JOIN target_info ti
      ON FLOOR(p."filing_date" / 10000) = ti."filing_year"
    WHERE p."publication_number" <> 'US-9741766-B2'
),

/* their 4‑digit IPC codes */
pub_ipc4 AS (
    SELECT DISTINCT
        sp."publication_number",
        SUBSTR(ipc_u.value:"code"::STRING, 1, 4) AS "ipc4"
    FROM same_year_pubs sp
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" pub
      ON pub."publication_number" = sp."publication_number",
         LATERAL FLATTEN(input => pub."ipc") ipc_u
),

/* count of overlapping IPC4 codes with the target */
match_counts AS (
    SELECT
        pi."publication_number",
        COUNT(*) AS "overlap_count"
    FROM pub_ipc4 pi
    JOIN target_ipc4 ti
      ON pi."ipc4" = ti."ipc4"
    GROUP BY pi."publication_number"
)

/* top‑5 most similar patents */
SELECT
       "publication_number"
FROM   match_counts
ORDER BY "overlap_count" DESC NULLS LAST,
         "publication_number"
LIMIT 5;