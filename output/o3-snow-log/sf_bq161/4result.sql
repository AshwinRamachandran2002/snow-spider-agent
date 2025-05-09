WITH paad_patients AS (      -- all PAAD cases in TCGA clinical file
    SELECT DISTINCT "bcr_patient_barcode" AS participant
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP
    WHERE "acronym" = 'PAAD'
),
kras_tp53_mutations AS (     -- PAAD mutations that passed all quality filters
    SELECT DISTINCT 
           "ParticipantBarcode" AS participant,
           "Hugo_Symbol"
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study"   = 'PAAD'
      AND "FILTER"  = 'PASS'
      AND "Hugo_Symbol" IN ('KRAS','TP53')
),
kras_patients AS (           -- patients with a KRAS mutation
    SELECT DISTINCT participant
    FROM kras_tp53_mutations
    WHERE "Hugo_Symbol" = 'KRAS'
),
tp53_patients AS (           -- patients with a TP53 mutation
    SELECT DISTINCT participant
    FROM kras_tp53_mutations
    WHERE "Hugo_Symbol" = 'TP53'
),
both_patients AS (           -- patients mutated in BOTH genes
    SELECT k.participant
    FROM kras_patients k
    INNER JOIN tp53_patients t
           ON k.participant = t.participant
),
neither_patients AS (        -- PAAD patients mutated in NEITHER gene
    SELECT p.participant
    FROM paad_patients p
    LEFT JOIN kras_tp53_mutations m
           ON p.participant = m.participant
    WHERE m.participant IS NULL
),
cnts AS (                    -- tally the two groups
    SELECT  (SELECT COUNT(*) FROM both_patients)   AS both_cnt,
            (SELECT COUNT(*) FROM neither_patients) AS neither_cnt
)
SELECT  both_cnt - neither_cnt AS "net_difference"
FROM    cnts;