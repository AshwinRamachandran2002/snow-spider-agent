WITH paad_patients AS (        -- clinical follow-up cohort
    SELECT DISTINCT
           "bcr_patient_barcode"        AS patient_id
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP"
    WHERE  "acronym" = 'PAAD'
),

gene_mut_flags AS (            -- high-quality mutation calls (MC3, PASS only)
    SELECT
        "ParticipantBarcode"                    AS patient_id,
        MAX(CASE WHEN "Hugo_Symbol" = 'KRAS'  THEN 1 ELSE 0 END) AS kras_mut,
        MAX(CASE WHEN "Hugo_Symbol" = 'TP53'  THEN 1 ELSE 0 END) AS tp53_mut
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"  = 'PAAD'
      AND  "FILTER" = 'PASS'
      AND  "Hugo_Symbol" IN ('KRAS','TP53')
    GROUP  BY "ParticipantBarcode"
),

patient_mutation_status AS (   -- merge clinical & mutation data; mute missing to 0
    SELECT
        c.patient_id,
        COALESCE(m.kras_mut,0)  AS kras_mut,
        COALESCE(m.tp53_mut,0)  AS tp53_mut
    FROM   paad_patients c
    LEFT JOIN gene_mut_flags m
           ON c.patient_id = m.patient_id
),

contingency AS (               -- 2×2 table counts
    SELECT
        SUM(CASE WHEN kras_mut = 1 AND tp53_mut = 1 THEN 1 ELSE 0 END) AS a,  -- KRAS+ / TP53+
        SUM(CASE WHEN kras_mut = 1 AND tp53_mut = 0 THEN 1 ELSE 0 END) AS b,  -- KRAS+ / TP53-
        SUM(CASE WHEN kras_mut = 0 AND tp53_mut = 1 THEN 1 ELSE 0 END) AS c,  -- KRAS- / TP53+
        SUM(CASE WHEN kras_mut = 0 AND tp53_mut = 0 THEN 1 ELSE 0 END) AS d   -- KRAS- / TP53-
    FROM   patient_mutation_status
),

chi_squared AS (                -- apply χ² formula for 2×2 tables
    SELECT
        a, b, c, d,
        (a+b+c+d)                                   AS n_total,
        ( (a+b+c+d) * POWER((a*d - b*c),2) ) 
        / NULLIF( (a+b)*(c+d)*(a+c)*(b+d) , 0 )     AS chi_squared_statistic
    FROM contingency
)

SELECT *
FROM chi_squared;