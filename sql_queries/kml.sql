
-- Generate KML from SQL
SELECT
  xmlelement(
    NAME kml, XMLATTRIBUTES ('http://www.opengis.net/kml/2.2' AS xmlns),
    xmlelement(
      NAME "Document", XMLATTRIBUTES ('doc_root' AS id),
      xmlelement(
        NAME "Folder",
        xmlelement(name "name", 'tablename'),
        xmlelement(
          NAME "Schema",
          XMLATTRIBUTES ('data' AS NAME, 'dataSchema' AS id),
          xmlelement(
            NAME "SimpleField", XMLATTRIBUTES ('[FieldType]' AS TYPE, '[FieldName]' AS NAME)
          ) -- repeat this for every field exclude layer.geom
        ),
        -- <Style id="[StyleID]"><LineStyle/><PolyStyle/></Style>
        xmlagg(placemarks)
      )
    )
  ) As document
FROM (
  SELECT 
    xmlelement(name "Placemark",
      xmlconcat(
        xmlelement(name "name", layer.id),
        xmlelement(name "description", layer.*),
        -- <TimeSpan><begin/><end/></TimeSpan>
        -- <styleUrl>#[StyleID]</styleUrl>
        xmlelement(
          NAME "ExtendedData",
          xmlelement(
            NAME "SchemaData",
            XMLATTRIBUTES ('#dataSchema' AS "schemaUrl"),
            xmlelement(
              NAME "SimpleData", XMLATTRIBUTES ('[FieldName]' AS NAME), layer.FieldName
            ) -- repeat this for every field exclude layer.geom
          )
        ),
        ST_AsKML(ST_Transform(geom, 4326), 9)::xml
      )
    )::xml As placemarks
  FROM tablename As layer
  WHERE ST_Transform(geom, 3857) 
    && ST_MakeEnvelope(minX, minY, maxX, maxY, 3857)
    -- check that the bbox of the geometry overlaps the tile bbox
    AND ST_Intersects(
      ST_Transform(geom, 3857),
      ST_MakeEnvelope(minX, minY, maxX, maxY, 3857)
    ) -- check that the geometry overlaps the tile bbox
) As placemarks
