WITH mut AS (   -- BRCA patients whose CDH1 mutation passed all quality filters
    SELECT DISTINCT
           m."ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
    WHERE  m."Study"        = 'BRCA'
      AND  m."Hugo_Symbol"  = 'CDH1'
      AND  m."FILTER"       = 'PASS'
),

base AS (        -- link clinical data to mutation status
    SELECT  c."bcr_patient_barcode"                 AS "ParticipantBarcode",
            c."histological_type",
            CASE WHEN mut."ParticipantBarcode" IS NOT NULL
                 THEN 'Mutated' ELSE 'WildType' END AS "mutation_status"
    FROM    PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    LEFT JOIN mut
           ON c."bcr_patient_barcode" = mut."ParticipantBarcode"
    WHERE   c."acronym"          = 'BRCA'
      AND   c."histological_type" IS NOT NULL
),

contingency AS ( -- observed counts per histology × mutation status
    SELECT  b."histological_type",
            b."mutation_status",
            COUNT(*) AS obs
    FROM    base b
    GROUP BY b."histological_type", b."mutation_status"
),

row_tot AS (     -- totals per histology
    SELECT  "histological_type",
            SUM(obs) AS row_total
    FROM    contingency
    GROUP BY "histological_type"
),

col_tot AS (     -- totals per mutation status
    SELECT  "mutation_status",
            SUM(obs) AS col_total
    FROM    contingency
    GROUP BY "mutation_status"
),

grand_tot AS (   -- grand total
    SELECT SUM(row_total) AS grand_total
    FROM   row_tot
),

valid_rows AS (  -- keep histology categories with >10 patients
    SELECT "histological_type"
    FROM   row_tot
    WHERE  row_total > 10
),

valid_cols AS (  -- keep mutation-status columns with >10 patients
    SELECT "mutation_status"
    FROM   col_tot
    WHERE  col_total > 10
),

cont_valid AS (  -- contingency table after marginal-count filtering
    SELECT c."histological_type",
           c."mutation_status",
           c.obs
    FROM   contingency c
    JOIN   valid_rows vr  ON c."histological_type" = vr."histological_type"
    JOIN   valid_cols vc  ON c."mutation_status"   = vc."mutation_status"
),

chi_parts AS (   -- χ² contribution of every cell
    SELECT  cv."histological_type",
            cv."mutation_status",
            cv.obs,
            rt.row_total,
            ct.col_total,
            gt.grand_total,
            POWER(cv.obs - (rt.row_total * ct.col_total) / gt.grand_total, 2)
            /
            ((rt.row_total * ct.col_total) / gt.grand_total)  AS chi_component
    FROM    cont_valid  cv
    JOIN    row_tot     rt ON cv."histological_type" = rt."histological_type"
    JOIN    col_tot     ct ON cv."mutation_status"   = ct."mutation_status"
    CROSS JOIN grand_tot gt
)

-- final χ² statistic
SELECT ROUND(SUM(chi_component), 4) AS "chi_square_value"
FROM   chi_parts;