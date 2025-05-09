WITH us_grants AS (
    SELECT 
        p."publication_number",
        p."ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS p
    WHERE p."country_code" = 'US'
      AND p."kind_code" = 'B2'          -- granted US utility patents
      AND p."application_kind" = 'A'    -- utility applications
      AND p."grant_date" BETWEEN 20220601 AND 20220831   -- Jun‒Aug 2022
),
ipc4_per_pub AS (
    /* extract distinct 4‑digit IPC codes per publication */
    SELECT DISTINCT
        g."publication_number",
        SUBSTR(f.value:"code"::string, 1, 4) AS ipc4
    FROM us_grants g,
         LATERAL FLATTEN(INPUT => g."ipc") f
    WHERE f.value:"code" IS NOT NULL
)
SELECT 
    ipc4,
    COUNT(*) AS publication_count
FROM ipc4_per_pub
GROUP BY ipc4
ORDER BY publication_count DESC NULLS LAST, ipc4
LIMIT 1;