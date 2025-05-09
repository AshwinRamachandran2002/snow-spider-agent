SELECT 
    SUBSTR(ipc_u.value:"code"::STRING, 1, 4) AS "Most_common_4_digit_IPC_code"
FROM 
    PATENTS.PATENTS.PUBLICATIONS t,
    LATERAL FLATTEN(input => t."ipc") ipc_u
WHERE 
    t."country_code" = 'US' 
    AND t."kind_code" = 'B2' 
    AND t."grant_date" BETWEEN 20220601 AND 20220831
GROUP BY 
    "Most_common_4_digit_IPC_code"
ORDER BY 
    COUNT(*) DESC NULLS LAST
LIMIT 1;