WITH t2_axial_studies AS (
    /* Studies in the collection that have at least one MR T2-weighted axial series */
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17."DICOM_ALL"
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND "SeriesDescription" ILIKE '%T2%'     -- T2-weighted
      AND "SeriesDescription" ILIKE '%AX%'     -- axial
),
peripheral_zone_studies AS (
    /* Studies that contain a segmentation whose SegmentedPropertyType is “Peripheral zone …” */
    SELECT DISTINCT d."StudyInstanceUID"
    FROM IDC.IDC_V17."SEGMENTATIONS" s
    JOIN IDC.IDC_V17."DICOM_ALL"      d
      ON d."SeriesInstanceUID" = s."SeriesInstanceUID"
    WHERE d."collection_id" = 'qin_prostate_repeatability'
      AND PARSE_JSON(s."SegmentedPropertyType"):"CodeMeaning"::STRING ILIKE '%Peripheral%zone%'
)
SELECT DISTINCT t."StudyInstanceUID"
FROM t2_axial_studies t
JOIN peripheral_zone_studies p
  ON t."StudyInstanceUID" = p."StudyInstanceUID";