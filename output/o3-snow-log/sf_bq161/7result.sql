WITH paad_patients AS (   -- all PAAD patients in TCGA clinical data
    SELECT DISTINCT SUBSTR("bcr_patient_barcode",1,12) AS participant
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP
    WHERE "acronym" = 'PAAD'
),

kras_mut AS (            -- PAAD patients with a PASS KRAS mutation
    SELECT DISTINCT "ParticipantBarcode" AS participant
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'PAAD'
      AND "Hugo_Symbol" = 'KRAS'
      AND "FILTER" = 'PASS'
),

tp53_mut AS (            -- PAAD patients with a PASS TP53 mutation
    SELECT DISTINCT "ParticipantBarcode" AS participant
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'PAAD'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),

both_mut AS (            -- patients mutated in BOTH KRAS and TP53
    SELECT participant FROM kras_mut
    INTERSECT
    SELECT participant FROM tp53_mut
),

either_mut AS (          -- patients mutated in EITHER KRAS or TP53
    SELECT participant FROM kras_mut
    UNION
    SELECT participant FROM tp53_mut
),

result AS (              -- compute requested counts
    SELECT
        (SELECT COUNT(*) FROM both_mut)                                             AS with_both,
        (SELECT COUNT(*) FROM paad_patients
          WHERE participant NOT IN (SELECT participant FROM either_mut))            AS without_either
)

SELECT
    with_both,
    without_either,
    with_both - without_either                                                      AS net_difference
FROM result;