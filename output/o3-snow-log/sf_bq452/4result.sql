WITH sample_groups AS (
    SELECT 
        "Sample"                                          AS SAMPLE_ID,
        CASE WHEN "Super_Population" = 'EAS' 
             THEN 'CASE' ELSE 'CTRL' END                 AS GROUP_TYPE
    FROM _1000_GENOMES._1000_GENOMES.SAMPLE_INFO
),    

call_expanded AS (   -- explode the per-sample calls for chr12
    SELECT 
        v."reference_name",
        v."start",
        v."end",
        c.value:"call_set_name"::string                  AS SAMPLE_ID,
        c.value:"genotype"[0]::integer                  AS g0,
        c.value:"genotype"[1]::integer                  AS g1
    FROM _1000_GENOMES._1000_GENOMES.VARIANTS v,
         LATERAL FLATTEN(input => v."call") c
    WHERE v."reference_name" = '12'
          AND c.value:"genotype"[0] IS NOT NULL
          AND c.value:"genotype"[1] IS NOT NULL
          AND c.value:"genotype"[0] IN (0,1)
          AND c.value:"genotype"[1] IN (0,1)
),

allele_counts AS (   -- count ref/alt alleles in each group
    SELECT
        ce."reference_name",
        ce."start",
        ce."end",
        sg.GROUP_TYPE,
        SUM( IFF(ce.g0 = 1,1,0) + IFF(ce.g1 = 1,1,0) )                    AS ALT_ALLELES,
        SUM( 2 - ( IFF(ce.g0 = 1,1,0) + IFF(ce.g1 = 1,1,0) ) )            AS REF_ALLELES
    FROM call_expanded ce
    JOIN sample_groups sg
      ON ce.SAMPLE_ID = sg.SAMPLE_ID
    GROUP BY ce."reference_name", ce."start", ce."end", sg.GROUP_TYPE
),

combined AS (        -- bring CASE and CTRL counts onto one row per variant
    SELECT
        "reference_name",
        "start",
        "end",
        MAX(IFF(GROUP_TYPE='CASE', ALT_ALLELES, NULL))     AS CASES_ALT,
        MAX(IFF(GROUP_TYPE='CASE', REF_ALLELES, NULL))     AS CASES_REF,
        MAX(IFF(GROUP_TYPE='CTRL', ALT_ALLELES, NULL))     AS CTRLS_ALT,
        MAX(IFF(GROUP_TYPE='CTRL', REF_ALLELES, NULL))     AS CTRLS_REF
    FROM allele_counts
    GROUP BY "reference_name", "start", "end"
),

stats AS (           -- row, column and total sums
    SELECT
        "reference_name", "start", "end",
        CASES_ALT, CASES_REF, CTRLS_ALT, CTRLS_REF,
        (CASES_ALT + CASES_REF)                        AS R1,
        (CTRLS_ALT + CTRLS_REF)                        AS R2,
        (CASES_ALT + CTRLS_ALT)                        AS C1,
        (CASES_REF + CTRLS_REF)                        AS C2
    FROM combined
    WHERE CASES_ALT IS NOT NULL AND CASES_REF IS NOT NULL
          AND CTRLS_ALT IS NOT NULL AND CTRLS_REF IS NOT NULL
),

expected AS (        -- expected counts for χ² test
    SELECT
        *,
        (R1 * C1) / (R1 + R2)                          AS E11,
        (R1 * C2) / (R1 + R2)                          AS E12,
        (R2 * C1) / (R1 + R2)                          AS E21,
        (R2 * C2) / (R1 + R2)                          AS E22,
        (R1 + R2)                                      AS N
    FROM stats
),

chi_calc AS (        -- Yates-corrected chi-square
    SELECT
        "start",
        "end",
        N,
        R1, R2, C1, C2,
        CASES_ALT, CASES_REF, CTRLS_ALT, CTRLS_REF,
        ( N * POWER( ABS(CASES_ALT * CTRLS_REF - CASES_REF * CTRLS_ALT) - (N / 2.0), 2) )
          / ( R1 * R2 * C1 * C2 )                     AS CHI_SQ
    FROM expected
    WHERE E11 >= 5 AND E12 >= 5 AND E21 >= 5 AND E22 >= 5     -- expected ≥5
)

SELECT 
    "start",
    "end",
    ROUND(CHI_SQ, 5)                                  AS CHI_SQUARED
FROM chi_calc
WHERE CHI_SQ >= 29.71679
ORDER BY CHI_SQ DESC NULLS LAST;