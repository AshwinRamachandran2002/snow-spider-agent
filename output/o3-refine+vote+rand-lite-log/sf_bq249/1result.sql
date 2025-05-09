SELECT 
       category,
       COUNT(*) AS "total_occurrences"
FROM (
        /* break every file’s text into individual lines */
        SELECT 
               CASE
                   WHEN REGEXP_LIKE(line,'[ \t]+$')          THEN 'trailing'      /* ends with blank (space or tab) */
                   WHEN SUBSTR(line,1,1) = ' '              THEN 'Space'         /* starts with a space            */
                   ELSE 'Other'                                                /* everything else                */
               END                                                     AS category
        FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
              LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) f,   /* explode to rows of lines        */
              LATERAL (SELECT f.value::string AS line) as ln
) 
GROUP BY category
ORDER BY category;