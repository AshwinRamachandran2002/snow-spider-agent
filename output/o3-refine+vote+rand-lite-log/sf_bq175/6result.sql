/*------------------------------------------------------------
   Cytobands on chromosome 1 whose amplifications, gains
   and heterozygous‑deletions each fall within the top‑11
   most‑frequent events in the TCGA‑KIRC allelic CNV data
------------------------------------------------------------*/
WITH segment_cats AS (          -- 1.  classify each CNV segment
    SELECT
        s."chromosome",
        s."start_pos",
        s."end_pos",
        CASE
            WHEN s."copy_number" > 3 THEN 'Amplification'      -- ≥ 4 copies
            WHEN s."copy_number" = 3 THEN 'Gain'               -- 3 copies
            WHEN s."copy_number" = 1 THEN 'HetDel'             -- 1 copy
        END                           AS "category"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    WHERE s."project_short_name" = 'TCGA-KIRC'
      AND s."chromosome" = 'chr1'
),
band_overlap AS (               -- 2.  map segments to cytobands
    SELECT
        cb."cytoband_name",
        sc."category"
    FROM segment_cats sc
    JOIN TCGA_MITELMAN.PROD."CYTOBANDS_HG38" cb
      ON cb."chromosome" = sc."chromosome"
     AND sc."start_pos" < cb."hg38_stop"
     AND sc."end_pos"   > cb."hg38_start"
    WHERE sc."category" IS NOT NULL
      AND cb."chromosome" = 'chr1'
),
band_counts AS (                -- 3.  count events per cytoband
    SELECT
        "cytoband_name",
        SUM(CASE WHEN "category" = 'Amplification' THEN 1 ELSE 0 END) AS "amp_cnt",
        SUM(CASE WHEN "category" = 'Gain'          THEN 1 ELSE 0 END) AS "gain_cnt",
        SUM(CASE WHEN "category" = 'HetDel'        THEN 1 ELSE 0 END) AS "hetdel_cnt"
    FROM band_overlap
    GROUP BY "cytoband_name"
),
ranked AS (                      -- 4.  rank cytobands by each event type
    SELECT
        bc.*,
        DENSE_RANK() OVER (ORDER BY "amp_cnt"   DESC) AS "amp_rank",
        DENSE_RANK() OVER (ORDER BY "gain_cnt"  DESC) AS "gain_rank",
        DENSE_RANK() OVER (ORDER BY "hetdel_cnt"DESC) AS "hetdel_rank"
    FROM band_counts bc
)
-- 5.  final selection – bands that are top‑11 for *all* three categories
SELECT
    "cytoband_name",
    "amp_cnt",
    "gain_cnt",
    "hetdel_cnt"
FROM ranked
WHERE "amp_rank"   <= 11
  AND "gain_rank"  <= 11
  AND "hetdel_rank"<= 11
ORDER BY "cytoband_name";