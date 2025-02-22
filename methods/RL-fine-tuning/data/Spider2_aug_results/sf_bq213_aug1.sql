-- Task: List the 4-digit IPC codes among US B2 utility patents granted from June to August in 2022, along with the number of patents for each code, ordered by most to least common.
WITH interim_table as(
    SELECT 
        t1."publication_number", 
        SUBSTR(ipc_u.value:"code", 0, 4) as ipc4
    FROM 
        PATENTS.PATENTS.PUBLICATIONS t1,
        LATERAL FLATTEN(input => t1."ipc") AS ipc_u
    WHERE
        "country_code" = 'US'  
        AND "grant_date" BETWEEN 20220601 AND 20220831
        AND "grant_date" != 0
        AND "publication_number" LIKE '%B2%'  
    GROUP BY 
        t1."publication_number", 
        ipc4
) 
SELECT 
    ipc4,
    COUNT("publication_number") AS num_patents
FROM 
    interim_table 
GROUP BY 
    ipc4
ORDER BY 
    num_patents DESC
LIMIT 100