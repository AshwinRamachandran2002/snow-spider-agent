WITH TARGET_YEAR AS (
    SELECT TO_NUMBER(SUBSTR(CAST("filing_date" AS VARCHAR), 1, 4)) AS "YR"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "publication_number" = 'US-9741766-B2'
), 

TARGET_VEC AS (
    SELECT  
        f."INDEX"                        AS "IDX",
        f."VALUE"::FLOAT                 AS "VAL"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a,
         LATERAL FLATTEN(input => a."embedding_v1") f
    WHERE a."publication_number" = 'US-9741766-B2'
), 

CANDIDATES AS (
    SELECT  
        p."publication_number",
        a."embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB   a
          ON a."publication_number" = p."publication_number"
    JOIN TARGET_YEAR  y
          ON TO_NUMBER(SUBSTR(CAST(p."filing_date" AS VARCHAR), 1, 4)) = y."YR"
    WHERE p."publication_number" <> 'US-9741766-B2'
      AND p."filing_date" IS NOT NULL
), 

CANDIDATE_VEC AS (
    SELECT  
        c."publication_number",
        f."INDEX"                       AS "IDX",
        f."VALUE"::FLOAT                AS "VAL"
    FROM CANDIDATES  c,
         LATERAL FLATTEN(input => c."embedding_v1") f
), 

SIMILARITY AS (
    SELECT  
        cv."publication_number",
        SUM(cv."VAL" * tv."VAL")        AS "SIM_SCORE"
    FROM CANDIDATE_VEC cv
    JOIN TARGET_VEC   tv
          ON cv."IDX" = tv."IDX"
    GROUP BY cv."publication_number"
)

SELECT "publication_number"
FROM SIMILARITY
ORDER BY "SIM_SCORE" DESC NULLS LAST
LIMIT 5;