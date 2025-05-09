WITH paad_patients AS (                     -- PAAD patients in clinical table
    SELECT DISTINCT 
           "bcr_patient_barcode" AS participantbarcode
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP
    WHERE "acronym" = 'PAAD'
),

paad_mutations AS (                         -- mutation flags for KRAS and TP53
    SELECT 
        "ParticipantBarcode"        AS participantbarcode,
        MAX(CASE WHEN "Hugo_Symbol" = 'KRAS' THEN 1 ELSE 0 END)  AS has_kras,
        MAX(CASE WHEN "Hugo_Symbol" = 'TP53' THEN 1 ELSE 0 END)  AS has_tp53
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study"  = 'PAAD'
      AND "FILTER" = 'PASS'
      AND "Hugo_Symbol" IN ('KRAS','TP53')
    GROUP BY "ParticipantBarcode"
),

combined AS (                              -- merge clinical list with mutation status
    SELECT 
        p.participantbarcode,
        COALESCE(m.has_kras ,0) AS has_kras,
        COALESCE(m.has_tp53,0) AS has_tp53
    FROM paad_patients p
    LEFT JOIN paad_mutations m
           ON p.participantbarcode = m.participantbarcode
),

summary AS (                               -- compute group counts
    SELECT
        SUM(CASE WHEN has_kras = 1 AND has_tp53 = 1 THEN 1 ELSE 0 END) AS patients_with_both,
        SUM(CASE WHEN has_kras = 0 AND has_tp53 = 0 THEN 1 ELSE 0 END) AS patients_with_neither
    FROM combined
)

SELECT                                      -- final result: net difference
       patients_with_both,
       patients_with_neither,
       patients_with_both - patients_with_neither AS net_difference
FROM summary;