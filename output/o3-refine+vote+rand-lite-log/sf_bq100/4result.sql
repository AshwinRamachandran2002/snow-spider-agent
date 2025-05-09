WITH extracted AS (
    SELECT
        REGEXP_REPLACE(                        -- drop the surrounding quotes
            REGEXP_SUBSTR(line , '"([^"]+)"'   -- grab text between the first pair of quotes
                        , 1 , 1 , 'e') ,
            '^"|"$' , ''
        )                         AS "PACKAGE"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  sc,
         LATERAL FLATTEN( INPUT => SPLIT(sc."content", '\n') ) fl,          -- split file into lines
         LATERAL (SELECT TRIM(fl.VALUE::text) AS line)                     -- current line
    WHERE sc."content" ILIKE '%import (%'          -- file contains a multiline import block
      AND line LIKE '"%"'                          -- line is inside the block (starts with a quote)
      AND REGEXP_SUBSTR(line , '"([^"]+)"') IS NOT NULL
)
SELECT  "PACKAGE",
        COUNT(*)             AS "FREQUENCY"
FROM    extracted
WHERE   "PACKAGE" IS NOT NULL
GROUP BY "PACKAGE"
ORDER BY "FREQUENCY" DESC NULLS LAST, "PACKAGE"
LIMIT 10;