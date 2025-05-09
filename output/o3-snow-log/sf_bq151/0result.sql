WITH paad_patients AS (          -- 1.  PAAD cohort
    SELECT DISTINCT 
           "bcr_patient_barcode"        AS "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP
    WHERE  "acronym" = 'PAAD'
),

patient_gene_flags AS (          -- 2.  Per-patient KRAS / TP53 mutation flags (PASS only)
    SELECT
        "ParticipantBarcode",
        MAX(CASE WHEN "Hugo_Symbol" = 'KRAS'  THEN 1 ELSE 0 END)  AS "KRAS_mut",
        MAX(CASE WHEN "Hugo_Symbol" = 'TP53' THEN 1 ELSE 0 END)  AS "TP53_mut"
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE  "FILTER" = 'PASS'
      AND  "Hugo_Symbol" IN ('KRAS','TP53')
      AND  "ParticipantBarcode" IN (SELECT "ParticipantBarcode" FROM paad_patients)
    GROUP BY "ParticipantBarcode"
),

patient_status AS (              -- 3.  Merge with cohort; patients without mutations get 0/0
    SELECT
        p."ParticipantBarcode",
        COALESCE(f."KRAS_mut",0)  AS "KRAS_mut",
        COALESCE(f."TP53_mut",0)  AS "TP53_mut"
    FROM   paad_patients p
    LEFT  JOIN patient_gene_flags f
           ON p."ParticipantBarcode" = f."ParticipantBarcode"
),

contingency AS (                 -- 4.  2×2 table counts
    SELECT
        SUM(CASE WHEN "KRAS_mut" = 1 AND "TP53_mut" = 1 THEN 1 ELSE 0 END) AS "both_mut",
        SUM(CASE WHEN "KRAS_mut" = 1 AND "TP53_mut" = 0 THEN 1 ELSE 0 END) AS "kras_only",
        SUM(CASE WHEN "KRAS_mut" = 0 AND "TP53_mut" = 1 THEN 1 ELSE 0 END) AS "tp53_only",
        SUM(CASE WHEN "KRAS_mut" = 0 AND "TP53_mut" = 0 THEN 1 ELSE 0 END) AS "neither"
    FROM patient_status
)

-- 5.  Chi-square statistic (no Yates correction)
SELECT
    "both_mut",
    "kras_only",
    "tp53_only",
    "neither",
    ("both_mut" + "kras_only" + "tp53_only" + "neither")                                     AS "N_total",
    ( POWER( ("both_mut" * "neither") - ("kras_only" * "tp53_only"), 2 )
      * ("both_mut" + "kras_only" + "tp53_only" + "neither") )
    /
    ( ("both_mut" + "kras_only")     * ("tp53_only" + "neither")
      * ("both_mut" + "tp53_only")   * ("kras_only" + "neither") )                           AS "chi_squared_statistic"
FROM contingency;