/* ---------------------------------------------------------------------------
   Frequency of CNV sub-types per cytoband for TCGA-KIRC
   ---------------------------------------------------------------------------
   1.  Restrict to TCGA-KIRC rows in the allelic segment table.
   2.  Keep only segments that overlap a cytoband (LEAST/ GREATEST test).
   3.  For every (case, cytoband) take the maximum copy_number.
   4.  Convert that maximum to a CNV class.
   5.  Count distinct cases in each (cytoband, CNV-class).
   6.  Divide by the total number of KIRC cases to obtain the percentage.
   7.  Show the result ordered by chromosome and cytoband position.
--------------------------------------------------------------------------- */
WITH kirc_cases AS (          -- total number of KIRC cases  (denominator)
    SELECT COUNT(DISTINCT "case_barcode") AS "total_cases"
    FROM   "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE  "project_short_name" = 'TCGA-KIRC'
),
segment_band_overlaps AS (    -- segment ↔ cytoband overlaps for KIRC
    SELECT
        s."case_barcode",
        b."cytoband_name",
        b."chromosome",
        b."hg38_start",
        s."copy_number"
    FROM   "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    JOIN   "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"                               b
           ON  s."chromosome" = b."chromosome"
    WHERE  s."project_short_name" = 'TCGA-KIRC'
      AND  LEAST(s."end_pos", b."hg38_stop")  >  GREATEST(s."start_pos", b."hg38_start")   -- true overlap
),
max_cn_by_case_band AS (      -- one row per (case, cytoband) with maximal CN
    SELECT
        "case_barcode",
        "cytoband_name",
        MAX("copy_number") AS "max_copy_number"
    FROM   segment_band_overlaps
    GROUP  BY "case_barcode", "cytoband_name"
),
classified AS (               -- translate max CN to a CNV class
    SELECT
        "case_barcode",
        "cytoband_name",
        CASE
            WHEN "max_copy_number" > 3 THEN 'Amplification'
            WHEN "max_copy_number" = 3 THEN 'Gain'
            WHEN "max_copy_number" = 2 THEN 'Normal'
            WHEN "max_copy_number" = 1 THEN 'Heterozygous Deletion'
            WHEN "max_copy_number" = 0 THEN 'Homozygous Deletion'
            ELSE 'Other'
        END AS "cnv_class"
    FROM   max_cn_by_case_band
),
cases_per_band_class AS (     -- number of KIRC cases in each class / band
    SELECT
        "cytoband_name",
        "cnv_class",
        COUNT(DISTINCT "case_barcode") AS "num_cases_in_class"
    FROM   classified
    GROUP  BY "cytoband_name", "cnv_class"
),
band_coords AS (              -- helper: one coordinate row per cytoband
    SELECT
        "cytoband_name",
        MIN("chromosome")  AS "chromosome",
        MIN("hg38_start")  AS "hg38_start"
    FROM   "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
    GROUP  BY "cytoband_name"
)
SELECT
    c."cytoband_name",
    c."cnv_class",
    ROUND(100.0 * c."num_cases_in_class" / kc."total_cases", 2) AS "pct_cases"
FROM   cases_per_band_class   c
CROSS  JOIN kirc_cases        kc
JOIN   band_coords            b  ON c."cytoband_name" = b."cytoband_name"
-- sort by chromosome (numeric order) then by cytoband position
ORDER  BY
    CASE                                 -- convert chr to numeric for ordering
        WHEN b."chromosome" = 'chrX' THEN 23
        WHEN b."chromosome" = 'chrY' THEN 24
        ELSE TO_NUMBER(SUBSTR(b."chromosome", 4))
    END,
    b."hg38_start",
    c."cytoband_name",
    c."cnv_class";