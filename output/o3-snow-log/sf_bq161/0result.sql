WITH paad_patients AS (   -- all TCGA PAAD patients from clinical data
    SELECT DISTINCT 
           "bcr_patient_barcode" AS "ParticipantBarcode"
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP
    WHERE "acronym" = 'PAAD'
),

gene_mutations AS (       -- PAAD mutations that passed all filters for KRAS or TP53
    SELECT DISTINCT
           "ParticipantBarcode",
           CASE WHEN "Hugo_Symbol" = 'KRAS'  THEN 1 ELSE 0 END AS "is_kras",
           CASE WHEN "Hugo_Symbol" = 'TP53'  THEN 1 ELSE 0 END AS "is_tp53"
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'PAAD'
      AND "FILTER" = 'PASS'
      AND "Hugo_Symbol" IN ('KRAS','TP53')
),

patient_flags AS (        -- per-patient flags for KRAS / TP53 mutation status
    SELECT
           "ParticipantBarcode",
           MAX("is_kras")  AS "has_kras_mut",
           MAX("is_tp53")  AS "has_tp53_mut"
    FROM gene_mutations
    GROUP BY "ParticipantBarcode"
),

cohort AS (               -- merge clinical PAAD list with mutation flags
    SELECT
           p."ParticipantBarcode",
           COALESCE(f."has_kras_mut",0) AS "has_kras_mut",
           COALESCE(f."has_tp53_mut",0) AS "has_tp53_mut"
    FROM paad_patients p
    LEFT JOIN patient_flags f
           ON p."ParticipantBarcode" = f."ParticipantBarcode"
),

totals AS (               -- counts for requested categories
    SELECT
        SUM( CASE WHEN "has_kras_mut" = 1 AND "has_tp53_mut" = 1 THEN 1 ELSE 0 END ) AS "both_mutated",
        SUM( CASE WHEN "has_kras_mut" = 0 AND "has_tp53_mut" = 0 THEN 1 ELSE 0 END ) AS "neither_mutated"
    FROM cohort
)

SELECT 
       "both_mutated" - "neither_mutated" AS "net_difference"
FROM totals;