/* ---------------------------------------------------------------------------
   Copy-Number Variation (CNV) landscape for TCGA-BRCA
   – Release 23 allelic CN segments (hg38) versus cytobands                --
   ---------------------------------------------------------------------------
   1.  Grab all BRCA allelic CN segments (release 23)
   2.  Intersect every segment with every cytoband on the same chromosome
   3.  For each (case × cytoband) pair
           • compute the overlap-weighted average copy number
           • round to the nearest integer
           • translate the rounded value into a CNV class
   4.  For each cytoband, count how many BRCA cases fall in every CNV class
   5.  Convert those counts to % of total BRCA cases (two decimals)
--------------------------------------------------------------------------- */

WITH brca_segments AS (        -- 1) BRCA allelic CN segments, release 23
    SELECT
        "case_barcode",        -- assumed present in the table
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-BRCA'
),

cytobands AS (                 -- 2) hg38 cytoband coordinates
    SELECT
        "chromosome",
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
),

overlaps AS (                  -- 2) segment ⨝ cytoband with overlap length
    SELECT
        s."case_barcode",
        c."cytoband_name",
        c."hg38_start",
        c."hg38_stop",
        CASE
            WHEN s."end_pos" < c."hg38_start"
              OR s."start_pos" > c."hg38_stop"        THEN 0
            ELSE LEAST(s."end_pos",  c."hg38_stop")
               - GREATEST(s."start_pos", c."hg38_start") + 1
        END                                   AS "overlap_len",
        s."copy_number"
    FROM brca_segments  s
    JOIN cytobands      c
      ON s."chromosome" = c."chromosome"
),

band_case_cn AS (              -- 3) overlap-weighted CN per (case, band)
    SELECT
        "case_barcode",
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        ROUND(
            SUM("overlap_len" * "copy_number")
            / NULLIF(SUM("overlap_len"), 0)
        ) AS "rounded_cn"
    FROM overlaps
    WHERE "overlap_len" > 0
    GROUP BY
        "case_barcode",
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
),

band_case_type AS (            -- 3) translate CN into CNV class
    SELECT
        "case_barcode",
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        CASE
            WHEN "rounded_cn" = 0 THEN 'Homozygous Deletion'
            WHEN "rounded_cn" = 1 THEN 'Heterozygous Deletion'
            WHEN "rounded_cn" = 2 THEN 'Diploid'
            WHEN "rounded_cn" = 3 THEN 'Gain'
            WHEN "rounded_cn" > 3 THEN 'Amplification'
        END AS "cnv_type"
    FROM band_case_cn
),

total_cases AS (               -- 4) total number of BRCA cases
    SELECT COUNT(DISTINCT "case_barcode") AS "n_cases"
    FROM band_case_type
),

band_type_counts AS (          -- 4) counts of CNV classes per cytoband
    SELECT
        c."cytoband_name",
        c."hg38_start",
        c."hg38_stop",
        SUM(CASE WHEN b."cnv_type" = 'Homozygous Deletion'   THEN 1 ELSE 0 END) AS "homdel_cnt",
        SUM(CASE WHEN b."cnv_type" = 'Heterozygous Deletion' THEN 1 ELSE 0 END) AS "hetdel_cnt",
        SUM(CASE WHEN b."cnv_type" = 'Diploid'              THEN 1 ELSE 0 END) AS "diploid_cnt",
        SUM(CASE WHEN b."cnv_type" = 'Gain'                 THEN 1 ELSE 0 END) AS "gain_cnt",
        SUM(CASE WHEN b."cnv_type" = 'Amplification'        THEN 1 ELSE 0 END) AS "amp_cnt"
    FROM cytobands c
    LEFT JOIN band_case_type b
           ON c."cytoband_name" = b."cytoband_name"
    GROUP BY
        c."cytoband_name",
        c."hg38_start",
        c."hg38_stop"
),

final AS (                     -- 5) convert counts to percentages
    SELECT
        bt."cytoband_name",
        bt."hg38_start",
        bt."hg38_stop",
        ROUND(100.0 * bt."homdel_cnt" / NULLIF(tc."n_cases", 0), 2) AS "percent_homozygous_deletion",
        ROUND(100.0 * bt."hetdel_cnt" / NULLIF(tc."n_cases", 0), 2) AS "percent_heterozygous_deletion",
        ROUND(100.0 * bt."diploid_cnt" / NULLIF(tc."n_cases", 0), 2) AS "percent_diploid",
        ROUND(100.0 * bt."gain_cnt"   / NULLIF(tc."n_cases", 0), 2) AS "percent_gain",
        ROUND(100.0 * bt."amp_cnt"    / NULLIF(tc."n_cases", 0), 2) AS "percent_amplification"
    FROM band_type_counts bt
    CROSS JOIN total_cases  tc
)

SELECT *
FROM final
ORDER BY "cytoband_name" NULLS LAST;