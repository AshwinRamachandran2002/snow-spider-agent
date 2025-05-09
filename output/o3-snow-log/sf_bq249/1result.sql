SELECT
    /* lines that end with a space or tab */
    SUM(CASE 
            WHEN REGEXP_LIKE(t.value::STRING, '[ \t]$') THEN 1 
            ELSE 0 
        END) AS "total_trailing",
    
    /* lines that start with a space */
    SUM(CASE 
            WHEN REGEXP_LIKE(t.value::STRING, '^ ') THEN 1 
            ELSE 0 
        END) AS "total_space",
    
    /* every other line */
    SUM(CASE 
            WHEN NOT REGEXP_LIKE(t.value::STRING, '[ \t]$')
             AND NOT REGEXP_LIKE(t.value::STRING, '^ ') THEN 1 
            ELSE 0 
        END) AS "total_other"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c,
     LATERAL SPLIT_TO_TABLE(c."content", '\n') AS t;