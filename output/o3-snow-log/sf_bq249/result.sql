SELECT  
        SUM(CASE WHEN REGEXP_LIKE(l.VALUE, '^[ ]')                              THEN 1 ELSE 0 END) AS "total_space_lines",
        SUM(CASE WHEN REGEXP_LIKE(l.VALUE, '[ \t]$')                            THEN 1 ELSE 0 END) AS "total_trailing_lines",
        SUM(CASE WHEN NOT REGEXP_LIKE(l.VALUE, '^[ ]') 
                      AND NOT REGEXP_LIKE(l.VALUE, '[ \t]$')                    THEN 1 ELSE 0 END) AS "total_other_lines"
FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  AS c,
        LATERAL SPLIT_TO_TABLE(c."content", '\n')           AS l;