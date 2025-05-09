WITH t2_axial AS (
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE LOWER("collection_id") = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND LOWER(COALESCE("SeriesDescription", '')) LIKE '%t2%'
      AND LOWER(COALESCE("SeriesDescription", '')) LIKE '%ax%'
),
pz_seg AS (
    SELECT DISTINCT s."StudyInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS AS s
    JOIN IDC.IDC_V17.DICOM_ALL AS d
      ON s."SeriesInstanceUID" = d."SeriesInstanceUID"
    WHERE LOWER(d."collection_id") = 'qin_prostate_repeatability'
      AND LOWER(COALESCE(s."SegmentedPropertyType", '')) LIKE '%peripheral%'
      AND LOWER(COALESCE(s."SegmentedPropertyType", '')) LIKE '%zone%'
)
SELECT DISTINCT t."StudyInstanceUID"
FROM t2_axial AS t
JOIN pz_seg  AS p
  ON t."StudyInstanceUID" = p."StudyInstanceUID"
ORDER BY t."StudyInstanceUID";