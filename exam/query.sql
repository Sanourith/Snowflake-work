-- PARTIE REQUETES --
-- Création d'un stage pour stocker mes informations en format .txt
CREATE OR REPLACE STAGE matt_serrano_stage
  FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"' FIELD_DELIMITER=',');

list@MATT_SERRANO_STAGE;

-- Création d'une table temporaire pour stocker les réponses aux requêtes format 2 col : Query / Result
DROP TABLE IF EXISTS STAR_SCHEMA.Temp_Results;
CREATE OR REPLACE TEMPORARY TABLE Temp_Results (
    "Query" VARCHAR,
    Result VARCHAR
);

-- Donnez les titres des albums qui ont plus de 1 CD.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'Donnez les titres des albums qui ont plus de 1 CD.', "AlbumTitle" FROM Star_Schema.New_tracks 
WHERE "CD_number" > 1
GROUP BY "AlbumTitle";

-- Donnez les morceaux produits en 2000 ou en 2002.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'Donnez les morceaux produits en 2000 ou en 2002.', "TrackName" || ' (' || "ProductionYear" || ')' FROM Star_Schema.New_tracks 
-- SELECT "TRACKNAME", "ProductionYear" FROM Star_Schema.New_tracks 
WHERE "ProductionYear" IN (2000, 2002)
ORDER BY "ProductionYear" ASC;

-- Donnez le nom et le compositeur des morceaux de Rock et de Jazz.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'Donnez le nom et le compositeur des morceaux de Rock et de Jazz.', "TrackName" || ' - ' || "Composer" || ' - ' || "GenreName" FROM Star_Schema.New_tracks 
-- SELECT "TRACKNAME", "Composer", "GENRENAME" FROM Star_Schema.New_tracks 
WHERE "GenreName" IN ('Rock', 'Jazz');

-- Donnez les 10 albums les plus longs.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'Donnez les 10 albums les plus longs', "AlbumTitle" || ' - ' || sum("TrackTime") || ' ms' FROM Star_Schema.New_tracks 
-- SELECT "ALBUMTITLE", sum("TRACKTIME") AS "duration (ms)" FROM Star_Schema.New_tracks 
GROUP BY "AlbumTitle"
ORDER BY sum("TrackTime") DESC --"duration (ms)"
LIMIT 10;

-- Donnez le nombre d'albums produits pour chaque artiste.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'Donnez le nombre d albums produits pour chaque artiste', "ArtistName" || ' - ' || count(distinct"AlbumId")   FROM Star_Schema.New_tracks
-- SELECT "ArtistName", count(distinct"AlbumId") AS nb_album FROM Star_Schema.New_tracks
GROUP BY "ArtistName"
ORDER BY "ArtistName" ASC;

-- Donnez le nombre de morceaux produits par chaque artiste.
INSERT INTO STAR_SCHEMA.Temp_Results 
SELECT 'Donnez le nombre de morceaux produits par chaque artiste', "ArtistName" || ' - ' || count("TrackId") FROM Star_Schema.New_tracks
-- SELECT "ArtistName", count("TrackId") AS Count FROM Star_Schema.New_tracks
GROUP BY "ArtistName";

-- Donnez le genre de musique le plus écouté dans les années 2000.
INSERT INTO STAR_SCHEMA.Temp_Results 
SELECT 'Donnez le genre de musique le plus écouté dans les années 2000', "GenreName" || ' - ' || count("TrackId") FROM Star_Schema.New_tracks
-- SELECT "GENRENAME", count("TrackId") AS nb_tracks FROM Star_Schema.New_tracks
WHERE "ProductionYear" BETWEEN 2000 AND 2009
GROUP BY "GenreName"
ORDER BY count("TrackId") DESC -- nb_tracks DESC
LIMIT 1;

-- Donnez les noms de toutes les playlists où figurent des morceaux de plus de 4 minutes.
-- 4 min = 4 x 60 x 1000 millisecond = 240000ms
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'Donnez les noms de toutes les playlists où figurent des morceaux de plus de 4 minutes.', "PlayListName" FROM Star_Schema.New_tracks
-- SELECT DISTINCT "PLAYLISTNAME" FROM Star_Schema.New_tracks
WHERE "TrackTime" > 240000
GROUP BY "PlayListName";

-- Donnez les morceaux de Rock dont les artistes sont en France.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'Donnez les morceaux de Rock dont les artistes sont en France.', "TrackName" FROM Star_Schema.New_tracks
-- SELECT "TRACKNAME" FROM Star_Schema.New_tracks
WHERE "GENRENAME" = 'Rock' AND "Country" = 'France';

-- Donnez la moyenne des tailles des morceaux par genre musical.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'Donnez la moyenne des tailles des morceaux par genre musical.', "GenreName" || ' - ' || AVG("Memory (B)") || ' Bytes' FROM Star_Schema.New_tracks
-- SELECT "GenreName", AVG("Memory (B)") AS avg_size FROM Star_Schema.New_tracks
GROUP BY "GenreName";

-- Donnez les playlist où figurent des morceaux d'artistes nés avant 1990.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'Donnez les playlists où figurent des morceaux d artistes nés avant 1990.', "PlayListName" FROM Star_Schema.New_tracks
-- SELECT DISTINCT "PlayListName" FROM Star_Schema.New_tracks
WHERE "Birthyear" < 1990
GROUP BY "PlayListName";

-- copie des résultats dans mon fichier answer.txt : 
CREATE OR REPLACE FILE FORMAT text_format
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  FIELD_DELIMITER = '|'  -- Peut aussi être "," etc
  NULL_IF = ('NULL', 'null', '')
  COMPRESSION = NONE;
  
COPY INTO @matt_serrano_stage/answer.txt
FROM (SELECT "Query" || ': ' || Result AS Line FROM STAR_SCHEMA.Temp_Results)
FILE_FORMAT = (FORMAT_NAME = 'text_format')
SINGLE = TRUE;

list@MATT_SERRANO_STAGE;