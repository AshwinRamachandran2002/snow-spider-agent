/*  Most‑frequent IPC4 for every U.S. utility patent (kind_code = 'B2')
    granted between 1‑Jun‑2022 and 30‑Sep‑2022.
    Return only those patents whose selected IPC4 occurs in at least
    10 different patents of the same cohort.                                 */

WITH patents_2022Q3 AS (          -- restrict to requested cohort
    SELECT  p."publication_number",
            p."ipc" AS ipc_array
    FROM    PATENTS.PATENTS.PUBLICATIONS p
    WHERE   p."country_code"     = 'US'
      AND   p."kind_code"        = 'B2'
      AND   p."application_kind" = 'A'          -- utility patent
      AND   p."grant_date" BETWEEN 20220601 AND 20220930
      AND   p."ipc" IS NOT NULL
),

ipc_flat AS (                     -- explode IPC list, keep 4‑digit code
    SELECT  pf."publication_number",
            LOWER(SUBSTR(f.value:"code"::string , 1 , 4)) AS ipc4
    FROM    patents_2022Q3 pf,
            LATERAL FLATTEN( INPUT => pf.ipc_array ) f
    WHERE   f.value:"code" IS NOT NULL
),

ipc_freq_per_pub AS (             -- occurrences of each IPC4 inside a patent
    SELECT  "publication_number",
            ipc4,
            COUNT(*) AS cnt_in_pub
    FROM    ipc_flat
    GROUP BY "publication_number", ipc4
),

top_ipc_per_pub AS (              -- choose the most‑frequent IPC4 per patent
    SELECT  "publication_number",
            ipc4,
            ROW_NUMBER() OVER
            (PARTITION BY "publication_number"
             ORDER BY cnt_in_pub DESC, ipc4 ) AS rn
    FROM    ipc_freq_per_pub
),

main_ipc AS (                     -- keep only the selected IPC4 (rn = 1)
    SELECT  "publication_number",
            ipc4
    FROM    top_ipc_per_pub
    WHERE   rn = 1
),

ipc4_popularity AS (              -- in how many patents does each IPC4 appear?
    SELECT  ipc4,
            COUNT( DISTINCT "publication_number" ) AS patents_with_ipc4
    FROM    ipc_flat
    GROUP BY ipc4
)

SELECT  m."publication_number",
        m.ipc4  AS ipc4_code
FROM    main_ipc        m
JOIN    ipc4_popularity pop
      ON m.ipc4 = pop.ipc4
WHERE   pop.patents_with_ipc4 >= 10      -- at least 10 patents share the IPC4
ORDER BY m."publication_number";