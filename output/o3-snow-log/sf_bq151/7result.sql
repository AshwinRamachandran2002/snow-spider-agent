/*-----------------------------------------------------------
  Chi-squared test of association between KRAS and TP53
  mutations in TCGA pancreatic adenocarcinoma (PAAD) patients
------------------------------------------------------------*/
WITH paad_patients AS (          -- all PAAD cases with follow-up
    SELECT DISTINCT
           "bcr_patient_barcode"          AS participant
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP"
    WHERE  "acronym" = 'PAAD'
),
high_quality_patients AS (       -- remove patients the quality file marks “Do_not_use”
    SELECT  p.participant
    FROM    paad_patients p
    LEFT JOIN PANCANCER_ATLAS_2.PANCANCER_ATLAS."MERGED_SAMPLE_QUALITY_ANNOTATIONS" q
           ON q."patient_barcode" = p.participant
    WHERE   COALESCE(q."Do_not_use",'False') = 'False'
),
relevant_mutations AS (          -- PASS variants in KRAS / TP53 for PAAD
    SELECT DISTINCT
           "ParticipantBarcode"  AS participant,
           "Hugo_Symbol"
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"        = 'PAAD'
      AND  "FILTER"       = 'PASS'
      AND  "Hugo_Symbol" IN ('KRAS','TP53')
),
mutation_flags AS (              -- one row / patient with binary flags
    SELECT  h.participant,
            MAX(CASE WHEN r."Hugo_Symbol" = 'KRAS' THEN 1 ELSE 0 END) AS has_kras,
            MAX(CASE WHEN r."Hugo_Symbol" = 'TP53' THEN 1 ELSE 0 END) AS has_tp53
    FROM    high_quality_patients h
    LEFT JOIN relevant_mutations r
           ON r.participant = h.participant
    GROUP BY h.participant
),
contingency AS (                 -- 2×2 table counts
    SELECT
        SUM(CASE WHEN has_kras = 1 AND has_tp53 = 1 THEN 1 ELSE 0 END) AS a,  -- KRAS + TP53
        SUM(CASE WHEN has_kras = 1 AND has_tp53 = 0 THEN 1 ELSE 0 END) AS b,  -- KRAS only
        SUM(CASE WHEN has_kras = 0 AND has_tp53 = 1 THEN 1 ELSE 0 END) AS c,  -- TP53 only
        SUM(CASE WHEN has_kras = 0 AND has_tp53 = 0 THEN 1 ELSE 0 END) AS d   -- neither
    FROM   mutation_flags
),
chi_squared AS (                 -- χ² statistic (no Yates’ correction)
    SELECT
        a, b, c, d,
        (a+b+c+d)                                                              AS n,
        /* χ² = N(ad−bc)² / ((a+b)(c+d)(a+c)(b+d)) */
        ((a*d - b*c)*(a*d - b*c) * (a+b+c+d)::FLOAT) /
        NULLIF( (a+b)*(c+d)*(a+c)*(b+d), 0)                                    AS chi_square
    FROM   contingency
)
SELECT *
FROM   chi_squared;