-- DATA LOADING PART, tutorial
-- for this training, i must delete AWS credentials, then you might adapt tables & data from kaggle folder.

-- Drop and recreate the database if it already exists
drop database if exists sanou_database;
create database sanou_database;

-- Create a connection to the S3 bucket
create stage s3_data
  url = 's3'
  credentials = (aws_key_id='access_key',
                aws_secret_key='secret_key'); 

-- Define the .csv file format
-- DROP FILE FORMAT CLASSIC_CSV;
CREATE FILE FORMAT CLASSIC_CSV;

ALTER FILE FORMAT "sanou_database"."PUBLIC".CLASSIC_CSV 
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

-- View music data in the S3 bucket
list @s3_data;
list @s3_data/music;

-- IMPLEMENTATION AND POPULATION OF TABLES:
-- PlaylistTrack Table
CREATE TABLE IF NOT EXISTS PUBLIC.PlaylistTrack (
    "PlaylistId" NUMBER,
    "TrackId" NUMBER,
    CONSTRAINT pk_playlist_track PRIMARY KEY ("PlaylistId", "TrackId"),
    CONSTRAINT fk_playlist FOREIGN KEY ("PlaylistId") 
        REFERENCES PUBLIC.Playlist("PlaylistId"),
    CONSTRAINT fk_track FOREIGN KEY ("TrackId") 
        REFERENCES PUBLIC.Track("TrackId")
);

-- Playlist Table
CREATE TABLE IF NOT EXISTS PUBLIC.Playlist (
    "PlaylistId" NUMBER PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL
);

-- Track Table
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

-- Genre Table
CREATE TABLE IF NOT EXISTS PUBLIC.Genre (
    "GenreId" NUMBER PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL
);

-- MediaType Table
CREATE TABLE IF NOT EXISTS PUBLIC.MediaType (
    "MediaTypeId" NUMBER PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL
);

-- Artist Table
CREATE TABLE IF NOT EXISTS PUBLIC.Artist (
    "ArtistId" NUMBER PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL,
    "Birthyear" NUMBER,
    "Country" VARCHAR(255)
);

-- Album Table
CREATE TABLE IF NOT EXISTS PUBLIC.Album (
    "AlbumId" NUMBER PRIMARY KEY,
    "Title" VARCHAR(255) NOT NULL,
    "ArtistId" NUMBER,
    "Prod_year" NUMBER,  -- different from schema check column names in CSV file
    "Cd_year" NUMBER,    -- different from schema check column names in CSV file
    CONSTRAINT fk_album_artist FOREIGN KEY ("ArtistId") 
        REFERENCES PUBLIC.Artist("ArtistId")
);
-- Check columns in the CSV file to retain correct values
SELECT  a.$1, a.$2, a.$3, a.$4, a.$5  FROM @s3_data/music/Album.csv a LIMIT 5;
ALTER TABLE PUBLIC.Album
    RENAME COLUMN "Prod_year" TO "ProductionYear";
ALTER TABLE PUBLIC.Album 
    RENAME COLUMN "Cd_year" TO "CD_number";

-- Load data from .csv files into the database
COPY INTO PUBLIC.Album
FROM @s3_data/music/Album.csv
FILE_FORMAT = (FORMAT_NAME = "sanou_database"."PUBLIC".CLASSIC_CSV);   --

COPY INTO PUBLIC.Artist
FROM @s3_data/music/Artist.csv
FILE_FORMAT = (FORMAT_NAME = "sanou_database"."PUBLIC".CLASSIC_CSV);   --

COPY INTO PUBLIC.Genre
FROM @s3_data/music/Genre.csv
FILE_FORMAT = (FORMAT_NAME = "sanou_database"."PUBLIC".CLASSIC_CSV);   --

COPY INTO PUBLIC.MediaType
FROM @s3_data/music/MediaType.csv
FILE_FORMAT = (FORMAT_NAME = "sanou_database"."PUBLIC".CLASSIC_CSV);   --

COPY INTO PUBLIC.Playlist
FROM @s3_data/music/Playlist.csv
FILE_FORMAT = (FORMAT_NAME = "sanou_database"."PUBLIC".CLASSIC_CSV);   --

COPY INTO PUBLIC.PlaylistTrack
FROM @s3_data/music/PlaylistTrack.csv
FILE_FORMAT = (FORMAT_NAME = "sanou_database"."PUBLIC".CLASSIC_CSV);   --

COPY INTO PUBLIC.Track
FROM @s3_data/music/Track.csv
FILE_FORMAT = (FORMAT_NAME = "sanou_database"."PUBLIC".CLASSIC_CSV);   -- issue with column alignment?

-- MANIPULATIONS WHEN THERE IS ERROR :
-- Verify columns in Track table data
SELECT  a.$1, a.$2, a.$3, a.$4, a.$5, a.$6, a.$7, a.$8, a.$9, a.$10, a.$11, a.$12, a.$13, a.$14, a.$15 FROM @s3_data/music/Track.csv a;
-- Problem with column order; recreating PUBLIC.Track table
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
-- Remember to transfer data!
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
-- Drop old Track table
DROP TABLE PUBLIC.Track;
-- Rename Track_n to Track
ALTER TABLE PUBLIC.Track_n
RENAME TO Track;
-- Retry data insertion into Track
COPY INTO PUBLIC.Track
FROM @s3_data/music/Track.csv
FILE_FORMAT = (FORMAT_NAME = "sanou_database"."PUBLIC".CLASSIC_CSV);

--
-- Troubleshoot using a "trash" table to view errors by creating a dynamic table from .csv file
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

-- SELECT * FROM track_trash;

-- SELECT * 
-- FROM Track_trash
-- WHERE "[10]" IS NULL;

-- Formatting issue in Track! Create a new CSV file format
CREATE FILE FORMAT csv_error;

ALTER FILE FORMAT "sanou_database"."PUBLIC".CSV_ERROR 
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

-- Test with a new Track_n table
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
-- Retry loading Track data with the new format
-- We lose 124 rows by continuing after errors... Whatever u_u

COPY INTO PUBLIC.Track -- Use PUBLIC.Track_n for testing before PUBLIC.Track
FROM @s3_data/music/Track.csv
FILE_FORMAT = (FORMAT_NAME = "sanou_database"."PUBLIC".CSV_ERROR,
               ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE)
ON_ERROR = 'CONTINUE';

-- done
