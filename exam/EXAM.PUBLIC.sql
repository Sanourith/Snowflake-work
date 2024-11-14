-- créer une database
drop database exam_matthieu;
create database exam_matthieu;

-- récup mes identifiants pour python  
select current_account(); -- PS97145
select current_user(); -- SANOU

-- créer le lien avec le bucket s3
create stage s3_data
  url = 's3://course-snowflakes/sample/'
  credentials = (aws_key_id='access_key',
                aws_secret_key='secret_key'); 

-- format de fichier .csv 
-- DROP FILE FORMAT CLASSIC_CSV;
CREATE FILE FORMAT CLASSIC_CSV;

ALTER FILE FORMAT "EXAM_MATTHIEU"."PUBLIC".CLASSIC_CSV 
SET COMPRESSION = 'AUTO' 
RECORD_DELIMITER = '\n'
FIELD_DELIMITER = ',' 
SKIP_HEADER = 1 
DATE_FORMAT = 'AUTO' 
TIMESTAMP_FORMAT = 'AUTO'
FIELD_OPTIONALLY_ENCLOSED_BY = 'NONE'
TRIM_SPACE = FALSE
ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE 
ESCAPE = 'NONE' 
ESCAPE_UNENCLOSED_FIELD = '\134' 
NULL_IF = ('\\N');


-- retrouver les données music
list @s3_data;
list @s3_data/music;
list @s3_data/music/Album.csv;

-- CREATION DES TABLES DE MA DB 
-- Table Playlist
CREATE TABLE IF NOT EXISTS PUBLIC.Playlist (
    "PlaylistId" NUMBER PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL
);

-- Table Genre
CREATE TABLE IF NOT EXISTS PUBLIC.Genre (
    "GenreId" NUMBER PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL
);

-- Table MediaType
CREATE TABLE IF NOT EXISTS PUBLIC.MediaType (
    "MediaTypeId" NUMBER PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL
);

-- Table Artist
CREATE TABLE IF NOT EXISTS PUBLIC.Artist (
    "ArtistId" NUMBER PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL,
    "Birthyear" NUMBER,
    "Country" VARCHAR(255)
);

-- Table Album
CREATE TABLE IF NOT EXISTS PUBLIC.Album (
    "AlbumId" NUMBER PRIMARY KEY,
    "Title" VARCHAR(255) NOT NULL,
    "ArtistId" NUMBER,
    "Prod_year" NUMBER,  -- vérif énoncé sans "_" check le nom des colonnes .csv
    "Cd_year" NUMBER,    -- vérif énoncé sans "_" check le nom des colonnes .csv
    CONSTRAINT fk_album_artist FOREIGN KEY ("ArtistId") 
        REFERENCES PUBLIC.Artist("ArtistId")
);

-- Table Track
CREATE TABLE IF NOT EXISTS PUBLIC.Track (
    "TrackId" NUMBER PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL,
    "MediaTypeId" NUMBER,
    "GenreId" NUMBER,
    "AlbumId" NUMBER,
    "Composer" VARCHAR(255),
    "Milliseconds" NUMBER,
    "Bytes" NUMBER,
    "UnitPrice" DECIMAL(10, 2),
    CONSTRAINT fk_track_mediatype FOREIGN KEY ("MediaTypeId") 
        REFERENCES PUBLIC.MediaType("MediaTypeId"),
    CONSTRAINT fk_track_genre FOREIGN KEY ("GenreId") 
        REFERENCES PUBLIC.Genre("GenreId"),
    CONSTRAINT fk_track_album FOREIGN KEY ("AlbumId") 
        REFERENCES PUBLIC.Album("AlbumId")
);

-- Table PlaylistTrack
CREATE TABLE IF NOT EXISTS PUBLIC.PlaylistTrack (
    "PlaylistId" NUMBER,
    "TrackId" NUMBER,
    CONSTRAINT pk_playlist_track PRIMARY KEY ("PlaylistId", "TrackId"),
    CONSTRAINT fk_playlist FOREIGN KEY ("PlaylistId") 
        REFERENCES PUBLIC.Playlist("PlaylistId"),
    CONSTRAINT fk_track FOREIGN KEY ("TrackId") 
        REFERENCES PUBLIC.Track("TrackId")
);


-- modif des deux colonnes arbitraires dans ALBUM
SELECT  a.$1, a.$2, a.$3, a.$4, a.$5  FROM @s3_data/music/Album.csv a LIMIT 5;
ALTER TABLE PUBLIC.Album
    RENAME COLUMN "Prod_year" TO "ProductionYear";
ALTER TABLE PUBLIC.Album 
    RENAME COLUMN "Cd_year" TO "CD_number";

-- intégration des données du .csv vers ma base
list @s3_data/music;
COPY INTO PUBLIC.Album
FROM @s3_data/music/Album.csv
FILE_FORMAT = (FORMAT_NAME = "EXAM_MATTHIEU"."PUBLIC".CLASSIC_CSV);   --

COPY INTO PUBLIC.Artist
FROM @s3_data/music/Artist.csv
FILE_FORMAT = (FORMAT_NAME = "EXAM_MATTHIEU"."PUBLIC".CLASSIC_CSV);   --

COPY INTO PUBLIC.Genre
FROM @s3_data/music/Genre.csv
FILE_FORMAT = (FORMAT_NAME = "EXAM_MATTHIEU"."PUBLIC".CLASSIC_CSV);   --

COPY INTO PUBLIC.MediaType
FROM @s3_data/music/MediaType.csv
FILE_FORMAT = (FORMAT_NAME = "EXAM_MATTHIEU"."PUBLIC".CLASSIC_CSV);   --

COPY INTO PUBLIC.Playlist
FROM @s3_data/music/Playlist.csv
FILE_FORMAT = (FORMAT_NAME = "EXAM_MATTHIEU"."PUBLIC".CLASSIC_CSV);   --

COPY INTO PUBLIC.PlaylistTrack
FROM @s3_data/music/PlaylistTrack.csv
FILE_FORMAT = (FORMAT_NAME = "EXAM_MATTHIEU"."PUBLIC".CLASSIC_CSV);   --

COPY INTO PUBLIC.Track
FROM @s3_data/music/Track.csv
FILE_FORMAT = (FORMAT_NAME = "EXAM_MATTHIEU"."PUBLIC".CLASSIC_CSV);   -- erreur d'insertion, pb colonnes ?
-- vérif table Track 
SELECT  a.$1, a.$2, a.$3, a.$4, a.$5, a.$6, a.$7, a.$8, a.$9, a.$10, a.$11, a.$12, a.$13, a.$14, a.$15 FROM @s3_data/music/Track.csv a;
-- je dois recréer une table pour changer l'ordre des colonnes
CREATE TABLE IF NOT EXISTS PUBLIC.Track_n (
    "TrackId" NUMBER PRIMARY KEY,
    "Title" VARCHAR(255) NOT NULL,
    "AlbumId" NUMBER,
    "MediaTypeId" NUMBER,
    "GenreId" NUMBER,
    "Composer" VARCHAR(255),
    "Milliseconds" NUMBER,
    "Bytes" NUMBER,
    "UnitPrice" DECIMAL(10, 2),
    CONSTRAINT fk_track_mediatype FOREIGN KEY ("MediaTypeId") 
        REFERENCES PUBLIC.MediaType("MediaTypeId"),
    CONSTRAINT fk_track_genre FOREIGN KEY ("GenreId") 
        REFERENCES PUBLIC.Genre("GenreId"),
    CONSTRAINT fk_track_album FOREIGN KEY ("AlbumId") 
        REFERENCES PUBLIC.Album("AlbumId")
);

-- PENSER A TRANSFERER LES DONNEES !!
INSERT INTO PUBLIC.Track_n
SELECT 
    "TrackId",
    "Name",
    "Composer",
    "MediaTypeId",
    "GenreId",
    "AlbumId",
    "Milliseconds",
    "Bytes",
    "UnitPrice"
FROM PUBLIC.Track;

-- drop track
DROP TABLE PUBLIC.Track;

-- je change le nom de Track_n
ALTER TABLE PUBLIC.Track_n
RENAME TO Track;

-- Je rééssaie d'intégrer les données track
COPY INTO PUBLIC.Track
FROM @s3_data/music/Track.csv
FILE_FORMAT = (FORMAT_NAME = "EXAM_MATTHIEU"."PUBLIC".CLASSIC_CSV);

-- Table Track_trash pour tier les "bonnes lignes" et garder les lignes KO de côté
-- Je veux essayer de mettre les données dynamiquement dans une table pour tier celles que je veux garder dans la DB prod "Track"
-- DROP TABLE PUBLIC.Track_trash;
-- CREATE TABLE IF NOT EXISTS PUBLIC.Track_trash (
--     "[1]" VARCHAR(255),
--     "[2]" VARCHAR(255),
--     "[3]" VARCHAR(255),
--     "[4]" VARCHAR(255),
--     "[5]" VARCHAR(255),
--     "[6]" VARCHAR(255),
--     "[7]" VARCHAR(255),
--     "[8]" VARCHAR(255),
--     "[9]" VARCHAR(255),
--     "[10]" VARCHAR(255),
--     "[11]" VARCHAR(255),
--     "[12]" VARCHAR(255),
--     "[13]" VARCHAR(255),
--     "[14]" VARCHAR(255)
-- );

-- INSERT INTO PUBLIC.Track_trash
-- SELECT  a.$1, a.$2, a.$3, a.$4, a.$5, a.$6, a.$7, a.$8, a.$9, a.$10, a.$11, a.$12, a.$13, a.$14
-- FROM @s3_data/music/Track.csv a;

-- select * from track_trash;

-- SELECT * 
-- FROM Track_trash
-- WHERE "[10]" IS NULL;

-- problème de format pour TRACK ! je crée un nouveau format de lecture CSV
CREATE FILE FORMAT csv_error;

ALTER FILE FORMAT "EXAM_MATTHIEU"."PUBLIC".CSV_ERROR 
SET COMPRESSION = 'AUTO' 
RECORD_DELIMITER = '\n'
FIELD_DELIMITER = ',' 
SKIP_HEADER = 1 
DATE_FORMAT = 'AUTO' 
TIMESTAMP_FORMAT = 'AUTO'
FIELD_OPTIONALLY_ENCLOSED_BY = 'NONE'
TRIM_SPACE = FALSE
ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE 
ESCAPE = 'NONE' 
ESCAPE_UNENCLOSED_FIELD = '\134' 
NULL_IF = ('\\N');

-- test avec une nouvelle table Track_n
-- DROP TABLE Track_n;
CREATE TABLE IF NOT EXISTS PUBLIC.Track_n (
    "TrackId" NUMBER PRIMARY KEY,
    "Title" VARCHAR(255) NOT NULL,
    "AlbumId" NUMBER,
    "MediaTypeId" NUMBER,
    "GenreId" NUMBER,
    "Composer" VARCHAR(255),
    "Milliseconds" NUMBER,
    "Bytes" NUMBER,
    "UnitPrice" DECIMAL(10, 2),
    CONSTRAINT fk_track_mediatype FOREIGN KEY ("MediaTypeId") 
        REFERENCES PUBLIC.MediaType("MediaTypeId"),
    CONSTRAINT fk_track_genre FOREIGN KEY ("GenreId") 
        REFERENCES PUBLIC.Genre("GenreId"),
    CONSTRAINT fk_track_album FOREIGN KEY ("AlbumId") 
        REFERENCES PUBLIC.Album("AlbumId")
);
-- On perd 124 lignes en faisant le contournement de l'erreur proposé dans l'énoncé :
-- mais on peut ajouter le csv pour les lignes qui sont correctement renseignées.
COPY INTO PUBLIC.Track -- PUBLIC.Track_n pour le test
FROM @s3_data/music/Track.csv
FILE_FORMAT = (FORMAT_NAME = "EXAM_MATTHIEU"."PUBLIC".CSV_ERROR,
               ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE)
ON_ERROR = 'CONTINUE';

-- star_schema
-- DROP SCHEMA Star_schema;
CREATE SCHEMA IF NOT EXISTS Star_schema;
USE SCHEMA Star_schema;

-- Pour mon schéma en étoile, je choisi la table de fait : Track, centrale dans l'analyse et simplification des requêtes sur les chansons.
-- Je la joins à Album, Genre, MediaType, Playlist, 
-- Je relie ensuite à Album <-> Artist et Playlist <-> PlaylistTrack
--              Artist
--              Album
-- Genre  ---- <Track>   ---- MediaType
--              Playlist
--              PlaylistTrack

--DROP TABLE Star_Schema.New_tracks;
CREATE TABLE Star_Schema.New_tracks (
"TrackId" NUMBER, 
"TrackName" VARCHAR(255), 
"Composer" VARCHAR(255), 
"TrackTime" NUMBER, 
"Memory (B)" NUMBER, 
"UnitPrice" DECIMAL(10, 2),
"AlbumId" NUMBER, 
"AlbumTitle" VARCHAR(255), 
"ProductionYear" NUMBER, 
"CD_number" NUMBER,
"ArtistId" NUMBER, 
"ArtistName" VARCHAR(255), 
"Birthyear" NUMBER, 
"Country" VARCHAR(255),
"GenreId" NUMBER, 
"GenreName" VARCHAR(255), 
"MediaTypeId" NUMBER, 
"MediaTypeName" VARCHAR(255), 
"PlaylistId" NUMBER, 
"PlayListName" VARCHAR(255)
);

insert all
into STAR_SCHEMA.New_Tracks ("TrackId", "TrackName", "Composer", "TrackTime", "Memory (B)", "UnitPrice",
                             "AlbumId", "AlbumTitle", "ProductionYear", "CD_number",
                             "ArtistId", "ArtistName", "Birthyear", "Country",
                             "GenreId", "GenreName", "MediaTypeId", "MediaTypeName", "PlaylistId", "PlayListName")
SELECT 
    t."TrackId" AS "TrackId",
    t."Title" AS "TrackName",
    t."Composer" AS "Composer",
    t."Milliseconds" AS "TrackTime",
    t."Bytes" AS "Memory (B)",
    t."UnitPrice" AS "UnitPrice",
    alb."AlbumId" AS "AlbumId",
    alb."Title" AS "AlbumTitle",
    alb."ProductionYear" AS "ProductionYear",
    alb."CD_number" AS "CD_number",
    art."ArtistId" AS "ArtistId",
    art."Name" AS "ArtistName",
    art."Birthyear" AS "Birthyear",
    art."Country" AS "Country",
    gen."GenreId" AS "GenreId",
    gen."Name" AS "GenreName",
    med."MediaTypeId" AS "MediaTypeId",
    med."Name" AS "MediaTypeName",
    pl."PlaylistId" AS "PlaylistId",
    pl."Name" AS "PlayListName"   
FROM PUBLIC.Track AS t
LEFT JOIN PUBLIC.Album AS alb ON t."AlbumId" = alb."AlbumId" 
LEFT JOIN PUBLIC.Artist AS art ON alb."ArtistId" = art."ArtistId" 
LEFT JOIN PUBLIC.Genre AS gen ON t."GenreId" = gen."GenreId" 
LEFT JOIN PUBLIC.MediaType AS med ON t."MediaTypeId" = med."MediaTypeId"
LEFT JOIN PUBLIC.PlaylistTrack AS plt ON t."TrackId" = plt."TrackId" 
LEFT JOIN PUBLIC.Playlist AS pl ON plt."PlaylistId" = pl."PlaylistId";

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
