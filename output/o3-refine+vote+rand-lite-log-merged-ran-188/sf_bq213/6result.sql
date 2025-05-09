WITH distinct_pub_ipc4 AS (
    SELECT DISTINCT 
           p."publication_number",
           LEFT(ip.value:"code"::STRING, 4) AS ipc4
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."ipc") ip
    WHERE p."country_code"      = 'US'
      AND p."kind_code"         = 'B2'        -- utility patent grants
      AND p."application_kind"  = 'A'         -- utility applications
      AND p."grant_date" BETWEEN 20220601 AND 20220831
)
SELECT 
       ipc4,
       COUNT(*) AS publication_count
FROM   distinct_pub_ipc4
GROUP  BY ipc4
ORDER  BY publication_count DESC NULLS LAST
LIMIT  1;