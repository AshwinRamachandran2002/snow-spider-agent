-- Task: Find the most frequent 4-character IPC code among US utility patents (publication numbers ending with 'B2') granted between June 1, 2022, and August 31, 2022, by extracting the first four characters of each IPC code from the "ipc" field associated with these patents.

WITH interim_table as(
SELECT 
    t1."publication_number", 
    SUBSTR(ipc_u.value:"code", 0, 4) as ipc4
FROM 
    PATENTS.PATENTS.PUBLICATIONS t1,
    LATERAL FLATTEN(input => t1."ipc") AS ipc_u
WHERE
    t1."country_code" = 'US'  
    AND t1."grant_date" BETWEEN 20220601 AND 20220831
    AND t1."grant_date" != 0
    AND t1."publication_number" LIKE '%B2%'  
GROUP BY 
    t1."publication_number", 
    ipc4
) 
SELECT 
    ipc4
FROM 
    interim_table 
GROUP BY 
    ipc4
ORDER BY 
    COUNT("publication_number") DESC
LIMIT 1