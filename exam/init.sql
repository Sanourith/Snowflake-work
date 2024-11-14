drop database if exists exam_matthieu;
create database exam_matthieu;

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

-- IMPLEMENTATION ET PEUPLEMENT DES TABLES :
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

-- Table Playlist
CREATE TABLE IF NOT EXISTS PUBLIC.Playlist (
    "PlaylistId" NUMBER PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL
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
-- vérification des colonnes du csv pour garder les bonnes valeurs
SELECT  a.$1, a.$2, a.$3, a.$4, a.$5  FROM @s3_data/music/Album.csv a LIMIT 5;
ALTER TABLE PUBLIC.Album
    RENAME COLUMN "Prod_year" TO "ProductionYear";
ALTER TABLE PUBLIC.Album 
    RENAME COLUMN "Cd_year" TO "CD_number";

-- intégration des données du .csv vers ma base
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
-- problème dans l'ordre des colonnes, je recrée la table PUBLIC.Track
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

--
-- Nouvelles erreurs je tente une table "POUBELLE" pour regarder les erreurs 
--
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

-- done
