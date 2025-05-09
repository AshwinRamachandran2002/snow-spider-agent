WITH PAAD_PATIENTS AS (          -- all PAAD cases in TCGA clinical file
    SELECT DISTINCT 
           "bcr_patient_barcode" AS ParticipantBarcode      -- alias (unquoted) => PARTICIPANTBARCODE
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP
    WHERE "acronym" = 'PAAD'
),  
MUTATIONS AS (                   -- high-quality KRAS / TP53 calls in PAAD
    SELECT DISTINCT
           "ParticipantBarcode"  AS ParticipantBarcode,     -- create matching alias
           "Hugo_Symbol"
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study"  = 'PAAD'
      AND "FILTER" = 'PASS'
      AND "Hugo_Symbol" IN ('KRAS','TP53')
),  
MUT_STATUS AS (                  -- per-patient mutation flags
    SELECT
        p.ParticipantBarcode,
        MAX(CASE WHEN m."Hugo_Symbol" = 'KRAS' THEN 1 ELSE 0 END) AS has_KRAS,
        MAX(CASE WHEN m."Hugo_Symbol" = 'TP53' THEN 1 ELSE 0 END) AS has_TP53
    FROM PAAD_PATIENTS p
    LEFT JOIN MUTATIONS m
           ON p.ParticipantBarcode = m.ParticipantBarcode   -- case now matches
    GROUP BY p.ParticipantBarcode
),  
AGG AS (                         -- tally required cohorts
    SELECT
        SUM(CASE WHEN has_KRAS = 1 AND has_TP53 = 1 THEN 1 ELSE 0 END) AS both_mutated,
        SUM(CASE WHEN has_KRAS = 0 AND has_TP53 = 0 THEN 1 ELSE 0 END) AS no_mutation
    FROM MUT_STATUS
)  
SELECT  both_mutated - no_mutation AS net_difference,
        both_mutated,
        no_mutation
FROM    AGG;